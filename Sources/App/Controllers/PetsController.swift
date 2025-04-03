import Fluent
import Vapor
import FluentKit
import FluentSQL
import SQLKit

struct PetsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let pets = routes.grouped("pets")
        let tokenProtected = pets.grouped(UserAuthenticator())
        pets.get(use: getAllPets)
        tokenProtected.on(.POST, body: .collect(maxSize: "20mb"), use: createPet)
        tokenProtected.delete(":petID", use: deletePetByID)
        tokenProtected.get("species", ":specie", use: getPetsBySpecie)
        tokenProtected.get("pet", ":petID", use: petByID)
        tokenProtected.get("shelter", use: getPetsFromShelter)
        tokenProtected.get("byDistance", use: getPetsByDistance)
        tokenProtected.get("byFilters", use: getPetsByFilter)
        tokenProtected.get("byShelter", ":shelterID", use: getPetsFromShelterByID)
    }
    
    @Sendable
    func createPet(req: Request) async throws -> HTTPStatus {
        _ = try await req.body.collect(max: 50).get()
        
        let user = try req.auth.require(User.self)
                
        let petFormData = try req.content.decode(PetFormData.self)
        
        guard let images = petFormData.images else {
            throw Abort(.badRequest, reason: "Image is required")
        }
        
        var imageURLs: [String] = []
        
        let directory = req.application.directory.publicDirectory + "pets/"
        try FileManager.default.createDirectory(
            atPath: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        for image in images {
            let byteBuffer =  image.data
            let publicDir = req.application.directory.publicDirectory
            let uploadsDir = publicDir + "pets"
            
            try FileManager.default.createDirectory(
                atPath: uploadsDir,
                withIntermediateDirectories: true
            )
            
            let fileName = "\(UUID().uuidString).jpg"
            let filePath = uploadsDir + "/\(fileName)"
            
            try await req.fileio.writeFile(byteBuffer, at: filePath)
            
            imageURLs.append("/pets/\(fileName)")
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
                name: petFormData.name,
                age: petFormData.age,
                description: petFormData.description,
                personality: petFormData.personality,
                idealHome: petFormData.idealHome,
                medicalCondition: petFormData.medicalCondition,
                adoptionInfo: petFormData.adoptionInfo,
                species: petFormData.species,
                breed: petFormData.breed,
                size: petFormData.size,
                gender: petFormData.gender,
                adoptionStatus: petFormData.adoptionStatus,
                imageURLs: imageURLs,
                latitude: userShelter.latitude,
                longitude: userShelter.longitude,
                location: nil
            )
            
            try await dbPet.save(on: req.db)
            
            guard let sqlDb = req.db as? SQLDatabase else {
                    throw Abort(.internalServerError, reason: "SQLDatabase no accesible.")
                }

            let locationString = "SRID=4326;POINT(\(dbPet.longitude) \(dbPet.latitude))"

            try await sqlDb.raw("""
                UPDATE pets SET location = ST_GeogFromText(\(bind: locationString))
                WHERE id = \(bind: dbPet.requireID())
            """).run()
            
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
    func getPetsByDistance(req: Request) async throws -> Page<PetResponseModel> {
        guard let userLat = req.query[Double.self, at: "lat"],
              let userLon = req.query[Double.self, at: "lon"] else {
            throw Abort(.badRequest, reason: "Se requieren los parámetros 'lat' y 'lon'.")
        }

        let radius: Double = req.query[Double.self, at: "radius"] ?? 3000000
        let page = req.query[Int.self, at: "page"] ?? 1
        let per = req.query[Int.self, at: "per"] ?? 5
        let offset = (page - 1) * per

        guard let sqlDb = req.db as? SQLDatabase else {
            throw Abort(.internalServerError, reason: "No se pudo acceder a SQLDatabase.")
        }

        let countQuery = SQLQueryString("""
            SELECT COUNT(*) AS total
            FROM pets
            WHERE ST_DWithin(pets.location, ST_MakePoint(\(literal: userLon), \(literal: userLat))::geography, \(literal: radius))
        """)
        
        struct CountResult: Decodable { let total: Int }
        let count = try await sqlDb.raw(countQuery).first(decoding: CountResult.self)?.total ?? 0

        let sql = SQLQueryString("""
            SELECT pets.*, ST_Distance(pets.location, ST_MakePoint(\(literal: userLon), \(literal: userLat))::geography) AS distance
            FROM pets
            WHERE ST_DWithin(pets.location, ST_MakePoint(\(literal: userLon), \(literal: userLat))::geography, \(literal: radius))
            ORDER BY distance ASC, id ASC
            LIMIT \(literal: per)
            OFFSET \(literal: offset)
        """)

        let pets = try await sqlDb.raw(sql).all(decoding: PetResponseModel.self)

        var models: [PetResponseModel] = []

        for pet in pets {
            models.append(
                PetResponseModel(
                    id: pet.id,
                    shelterID: pet.shelterID,
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
                    imageURLs: pet.imageURLs,
                    distance: pet.distance
                )
            )
        }

        return Page(
            items: models,
            metadata: PageMetadata(page: page, per: per, total: count)
        )
    }
    
    @Sendable
    func getAllPets(req: Request) async throws -> Page<Pet> {
        do {
            return try await Pet.query(on: req.db)
                .paginate(for: req)
        } catch {
            req.logger.error("ERROR REAL: \(String(reflecting: error))")
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
    func getPetsFromShelterByID(req: Request) async throws -> [Pet] {
        guard let shelterID = req.parameters.get("shelterID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid shelterID")
        }
        
        do {
            return try await Pet.query(on: req.db)
                .filter(\Pet.$shelter.$id == shelterID)
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

struct PetFormData: Content {
    let name: String
    let age: PetAge
    let description: String?
    let personality: String?
    let idealHome: String?
    let medicalCondition: String?
    let adoptionInfo: String?
    let breed: String
    let images: [File]?
    
    let size: PetSize
    let adoptionStatus: AdoptionStatus
    let species: Species
    let gender: PetGender
}

struct PetResponseModel: Content {
    let id: UUID?
    let shelterID: UUID
    let name: String
    let age: PetAge?
    let description: String?
    let personality: String?
    let idealHome: String?
    let medicalCondition: String?
    let adoptionInfo: String?
    let species: Species
    let breed: String?
    let size: PetSize
    let gender: PetGender
    let adoptionStatus: AdoptionStatus
    let imageURLs: [String]?
    let distance: Double
}

func makeLocationData(lat: Double, lon: Double) -> Data {
    let locationText = "SRID=4326;POINT(\(lon) \(lat))"
    return locationText.data(using: .utf8)!
}

//@Sendable
//func getPetsByDistance(req: Request) async throws -> [PetResponseModel] {
//    guard let userLat = req.query[Double.self, at: "lat"],
//          let userLon = req.query[Double.self, at: "lon"] else {
//        throw Abort(.badRequest, reason: "Se requieren los parámetros 'lat' y 'lon'.")
//    }
//    
//    let radius: Double = req.query[Double.self, at: "radius"] ?? 5000
//    
//    let pets = try await Pet.query(on: req.db).all()
//    
//    let petsResponse = pets
//        .map { pet -> (PetResponseModel, Double) in
//            let distance = DistanceCalculator.distance(from: userLat,
//                                                       lon1: userLon,
//                                                       to: pet.latitude,
//                                                       lon2: pet.longitude)
//            
//            let response = PetResponseModel(
//                shelter: pet.shelter,
//                name: pet.name,
//                age: pet.age,
//                description: pet.description,
//                personality: pet.personality,
//                idealHome: pet.idealHome,
//                medicalCondition: pet.medicalCondition,
//                adoptionInfo: pet.adoptionInfo,
//                species: pet.species,
//                breed: pet.breed,
//                size: pet.size,
//                gender: pet.gender,
//                adoptionStatus: pet.adoptionStatus,
//                imageURLs: pet.imageURLs,
//                distance: distance
//            )
//            
//            return (response, distance)
//        }
//        .filter { _, distance in
//            distance <= radius
//        }
//        .sorted { $0.1 < $1.1 }
//        .map { $0.0 }
//    
//    return petsResponse
//}


//@Sendable
//func getPetsByDistance(req: Request) async throws -> [PetResponseModel] {
//    guard let userLat = req.query[Double.self, at: "lat"],
//          let userLon = req.query[Double.self, at: "lon"] else {
//        throw Abort(.badRequest, reason: "Se requieren los parámetros 'lat' y 'lon'.")
//    }
//    
//    let radius: Double = req.query[Double.self, at: "radius"] ?? 5000
//    
//    return try await Pet.query(on: req.db)
//        .all()
//        .map { pet -> (Pet, Double) in
//            let petLat = pet.latitude
//            let petLon = pet.longitude
//            
//            let earthRadius = 6371000.0
//            
//            let latDiff = (petLat - userLat) * .pi / 180
//            let lonDiff = (petLon - userLon) * .pi / 180
//            let lat1 = userLat * .pi / 180
//            let lat2 = petLat * .pi / 180
//            
//            let a = sin(latDiff/2) * sin(latDiff/2) +
//            cos(lat1) * cos(lat2) *
//            sin(lonDiff/2) * sin(lonDiff/2)
//            let c = 2 * atan2(sqrt(a), sqrt(1-a))
//            let distance = earthRadius * c
//            
//            return (pet, distance)
//        }
//        .filter { _, distance in
//            distance <= radius
//        }
//        .sorted { $0.1 < $1.1 }
//        .map { $0.0 }
//}


//VERSION FUNCIONAL

/*
 @Sendable
 func getPetsByDistance(req: Request) async throws -> [PetResponseModel] {
     guard let userLat = req.query[Double.self, at: "lat"],
           let userLon = req.query[Double.self, at: "lon"] else {
         throw Abort(.badRequest, reason: "Se requieren los parámetros 'lat' y 'lon'.")
     }
 
     let radius: Double = req.query[Double.self, at: "radius"] ?? 300000
 
     let pets = try await Pet.query(on: req.db)
         .with(\.$shelter)
         .all()
 
     let petsResponse = pets
         .map { pet -> (PetResponseModel, Double) in
             let distance = DistanceCalculator.distance(from: userLat,
                                                        lon1: userLon,
                                                        to: pet.latitude,
                                                        lon2: pet.longitude)
 
             let response = PetResponseModel(
                 id: pet.id,
                 shelter: pet.shelter,
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
                 imageURLs: pet.imageURLs,
                 distance: distance
             )
 
             return (response, distance)
         }
         .filter { _, distance in
             distance <= radius
         }
         .sorted { $0.1 < $1.1 }
         .map { $0.0 }
 
     return petsResponse
 }
 */
