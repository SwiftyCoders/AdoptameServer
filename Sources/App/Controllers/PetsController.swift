import Fluent
import Vapor
import FluentKit
import FluentSQL

struct PetsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let pets = routes.grouped("pets")
        let tokenProtected = pets.grouped(UserAuthenticator())
        pets.get(use: getAllPets)
        tokenProtected.post(use: createPet)
        tokenProtected.delete(":petID", use: deletePetByID)
        tokenProtected.get("species", ":specie", use: getPetsBySpecie)
        tokenProtected.get("pet", ":petID", use: petByID)
        tokenProtected.get("shelter", use: getPetsFromShelter)
        tokenProtected.get("byDistance", use: getPetsByDistance)
        tokenProtected.get("byFilters", use: getPetsByFilter)
    }
    
    @Sendable
    func createPet(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        let pet = try req.content.decode(PetDTO.self)
        
        guard let imagesBase64 = pet.images else {
            throw Abort(.badRequest, reason: "Image is required")
        }
        
        var imageURLs: [String] = []
        
        let directory = req.application.directory.publicDirectory + "pets/"
        try FileManager.default.createDirectory(
            atPath: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        for image in imagesBase64 {
            let fileName = "\(UUID().uuidString).jpg"
            let filePath = "Public/pets/\(fileName)"
            let fileURLPath = "pets/\(fileName)"
            
            let regex = try! NSRegularExpression(pattern: "^data:image\\/(jpeg|png);base64,", options: [])
            let base64String = regex.stringByReplacingMatches(
                in: image,
                options: [],
                range: NSRange(location: 0, length: image.count),
                withTemplate: ""
            )
            
            //let base64String = image.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            guard let imageData = Data(base64Encoded: base64String) else {
                throw Abort(.badRequest, reason: "Invalid image data")
            }
            
            try await req.fileio.writeFile(
                ByteBuffer(data: imageData),
                at: filePath
            )
            
            imageURLs.append(fileURLPath)
        }
        
        guard let userShelterID = user.shelterID else {
            throw Abort(.notFound, reason: "User shelter ID Not found")
        }
        
        guard let userShelter = try await Shelter.query(on: req.db)
            .filter(\Shelter.$id == userShelterID)
            .first() else {
            throw Abort(.notFound, reason: "User Shelter Not found")
        }
        
        do {
            let dbPet = Pet(
                shelterID: userShelterID,
                name: pet.name,
                age: pet.age,
                description: pet.description,
                personality: pet.personality,
                idealHome: pet.idealHome,
                medicalCondition: pet.medicalCondition,
                adoptionInfo: pet.adoptionInfo,
                species: pet.species,
                breed: pet.breed,
                size: pet.size,
                gender: pet.gender,
                adoptionStatus: pet.adoptionStatus,
                imageURLs: imageURLs,  // Ahora guardamos todas las URLs
                latitude: userShelter.latitude,
                longitude: userShelter.longitude
            )
            
            try await dbPet.save(on: req.db)
            return .created
        } catch {
            print(String(reflecting: error))
            throw Abort(.badRequest, reason: "Cannot create new pet for shelter \(userShelter.name)")
        }
    }
    
    @Sendable
    func deletePetByID(req: Request) async throws -> HTTPStatus {
        guard let petID = req.parameters.get("petID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid petID")
        }
        
        guard let pet = try await Pet.find(petID, on: req.db) else {
            throw Abort(.notFound, reason: "Pet not found")
        }
        
        try await pet.delete(on: req.db)
        return .ok
    }
    
    @Sendable
    func updatePet(req: Request) async throws -> HTTPStatus {
        //        guard let petID = req.parameters.get("petID", as: UUID.self) else {
        //            throw Abort(.badRequest, reason: "Invalid petID")
        //        }
        //
        //        guard let pet = try await Pet.find(petID, on: req.db) else {
        //            throw Abort(.notFound, reason: "Pet not found")
        //        }
        //
        //        let updatedPet = Pet(
        //            shelterID: pet.shelter.id!,
        //            name: pet.name,
        //            description: pet.description,
        //            species: pet.species,
        //            size: pet.size,
        //            adoptionStatus: pet.adoptionStatus,
        //            latitude: pet.latitude,
        //            longitude: pet.longitude, gender: <#PetGender#>
        //        )
        //
        //        do {
        //            try await updatedPet.save(on: req.db)
        //            return .ok
        //        } catch {
        //            throw Abort(.badRequest, reason: "Cannot update Pet")
        //        }
        .ok
    }
    
    @Sendable
    func getPetsByDistance(req: Request) async throws -> [Pet] {
        guard let userLat = req.query[Double.self, at: "lat"],
              let userLon = req.query[Double.self, at: "lon"] else {
            throw Abort(.badRequest, reason: "Se requieren los parámetros 'lat' y 'lon'.")
        }
        
        let radius: Double = req.query[Double.self, at: "radius"] ?? 5000
        
        return try await Pet.query(on: req.db)
            .all()
            .map { pet -> (Pet, Double) in
                let petLat = pet.latitude
                let petLon = pet.longitude
                
                let earthRadius = 6371000.0
                
                let latDiff = (petLat - userLat) * .pi / 180
                let lonDiff = (petLon - userLon) * .pi / 180
                let lat1 = userLat * .pi / 180
                let lat2 = petLat * .pi / 180
                
                let a = sin(latDiff/2) * sin(latDiff/2) +
                cos(lat1) * cos(lat2) *
                sin(lonDiff/2) * sin(lonDiff/2)
                let c = 2 * atan2(sqrt(a), sqrt(1-a))
                let distance = earthRadius * c
                
                return (pet, distance)
            }
            .filter { _, distance in
                distance <= radius
            }
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
    }
    
    @Sendable
    func getAllPets(req: Request) async throws -> [Pet] {
        do {
            return try await Pet.query(on: req.db)
                .all()
        } catch {
            throw Abort(.badRequest, reason: "ERROR AL OBTENER TODOS LOS PETS REAL")
        }
    }
    
    @Sendable
    func getPetsBySpecie(req: Request) async throws -> [Pet] {
        guard let specieString = req.parameters.get("specie", as: String.self),
              let specieEnum = Species(rawValue: specieString) else {
            throw Abort(.badRequest, reason: "Specie type not found or invalid")
        }
        
        return try await Pet.query(on: req.db)
            .filter(\.$species == specieEnum)
            .all()
    }
    
    @Sendable
    func getPetsFromShelter(req: Request) async throws -> [Pet] {
        let user = try req.auth.require(User.self)
        
        guard let userShelterID = user.shelterID else { throw Abort(.notFound, reason: "Shelter ID not found")}
        
        do {
            return try await Pet.query(on: req.db)
                .filter(\Pet.$shelter.$id == userShelterID)
                .all()
        } catch {
            throw Abort(.notFound, reason: "Cannot get all Pets From Shelter: \(error)")
        }
    }
    
    @Sendable
    func petByID(req: Request) async throws -> Pet {
        guard let petID = req.parameters.get("petID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid petID")
        }
        
        guard let pet = try await Pet.find(petID, on: req.db) else {
            throw Abort(.notFound, reason: "Pet not found")
        }
        
        return pet
    }
    
    @Sendable
    func getPetsByFilter(req: Request) async throws -> [Pet] {
        let filter = try req.query.decode(PetFilterRequest.self)
        let query = Pet.query(on: req.db)
        
        if let types = filter.types, !types.isEmpty {
            query.filter(\Pet.$species ~~ types)
        }
        
        if let gender = filter.gender {
            query.filter(\Pet.$gender == gender)
        }
        
        if let size = filter.size {
            query.filter(\.$size == size)
        }
        
        if let age = filter.age {
            query.filter(\.$age == age)
        }
        
        return try await query.all()
    }
}

struct PetFilterRequest: Content {
    var types: [Species]?
    var gender: PetGender?
    var size: PetSize?
    var age: PetAge?
}
