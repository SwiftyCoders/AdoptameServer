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
    
//    @Sendable
//    func createPet2(req: Request) async throws -> HTTPStatus {
//        print("🚀 INICIO PET: \(Date.now)")
//
//        // 1. Asegurate de permitir un tamaño adecuado de cuerpo (50 MB por ejemplo)
//        _ = try await req.body.collect(max: 50 * 1024 * 1024).get()
//
//        let user = try req.auth.require(User.self)
//        let petFormData = try req.content.decode(PetFormData.self)
//
//        guard let images = petFormData.images else {
//            throw Abort(.badRequest, reason: "Image is required")
//        }
//
//        var imageURLs: [String] = []
//
//        // 2. Prepara el directorio una única vez
//        let uploadsDir = req.application.directory.publicDirectory + "pets/"
//        try FileManager.default.createDirectory(
//            atPath: uploadsDir,
//            withIntermediateDirectories: true,
//            attributes: nil
//        )
//
//        // 3. Medí el tiempo de escritura
//        let startWrite = Date()
//
//        // 4. Guardá todas las imágenes en paralelo
//        try await withThrowingTaskGroup(of: String.self) { group in
//            for image in images {
//                group.addTask {
//                    let byteBuffer = image.data
//                    let fileName = "\(UUID().uuidString).jpg"
//                    let filePath = uploadsDir + fileName
//                    try await req.fileio.writeFile(byteBuffer, at: filePath)
//                    return "/pets/\(fileName)"
//                }
//            }
//
//            for try await imageURL in group {
//                imageURLs.append(imageURL)
//            }
//        }
//
//        print("📝 Escritura de imágenes terminada en \(Date().timeIntervalSince(startWrite))s")
//
//        // 5. Obtener shelter del usuario
//        guard let userShelterID = user.shelterID else {
//            throw Abort(.notFound, reason: "User shelter ID Not found")
//        }
//
//        guard let userShelter = try await Shelter.query(on: req.db)
//            .filter(\Shelter.$id == userShelterID)
//            .first() else {
//            throw Abort(.notFound, reason: "User Shelter Not found")
//        }
//
//        // 6. Crear mascota en la base de datos
//        do {
//            let dbPet = Pet(
//                shelterID: userShelterID,
//                name: petFormData.name,
//                age: petFormData.age,
//                description: petFormData.description,
//                personality: petFormData.personality,
//                idealHome: petFormData.idealHome,
//                medicalCondition: petFormData.medicalCondition,
//                adoptionInfo: petFormData.adoptionInfo,
//                species: petFormData.species,
//                breed: petFormData.breed,
//                size: petFormData.size,
//                gender: petFormData.gender,
//                adoptionStatus: petFormData.adoptionStatus,
//                imageURLs: imageURLs,
//                latitude: userShelter.latitude,
//                longitude: userShelter.longitude,
//                location: nil
//            )
//
//            try await dbPet.save(on: req.db)
//
//            guard let sqlDb = req.db as? SQLDatabase else {
//                throw Abort(.internalServerError, reason: "SQLDatabase no accesible.")
//            }
//
//            let locationString = "SRID=4326;POINT(\(dbPet.longitude) \(dbPet.latitude))"
//
//            try await sqlDb.raw("""
//                UPDATE pets SET location = ST_GeogFromText(\(bind: locationString))
//                WHERE id = \(bind: dbPet.requireID())
//            """).run()
//
//            print("✅ FIN PET: \(Date.now)")
//            return .created
//
//        } catch {
//            print("❌ ERROR: \(String(reflecting: error))")
//            throw Abort(.badRequest, reason: "Cannot create new pet for shelter \(userShelter.name)")
//        }
//    }
    
    @Sendable
    func createPet(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let petFormData = try req.content.decode(PetFormData.self)

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
                imageURLs: petFormData.images,
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
            print("❌ ERROR: \(String(reflecting: error))")
            throw Abort(.badRequest, reason: "Cannot create new pet for shelter \(userShelter.name)")
        }
    }
    
//    @Sendable
//    func createPet(req: Request) async throws -> HTTPStatus {
//        print("EMPIEZO PET: \(Date.now)")
//        
//        _ = try await req.body.collect(max: 50).get()
//        
//        let user = try req.auth.require(User.self)
//                
//        let petFormData = try req.content.decode(PetFormData.self)
//        
//        guard let images = petFormData.images else {
//            throw Abort(.badRequest, reason: "Image is required")
//        }
//        
//        var imageURLs: [String] = []
//        
//        let directory = req.application.directory.publicDirectory + "pets/"
//        try FileManager.default.createDirectory(
//            atPath: directory,
//            withIntermediateDirectories: true,
//            attributes: nil
//        )
//        
//        for image in images {
//            let byteBuffer =  image.data
//            let publicDir = req.application.directory.publicDirectory
//            let uploadsDir = publicDir + "pets"
//            
//            try FileManager.default.createDirectory(
//                atPath: uploadsDir,
//                withIntermediateDirectories: true
//            )
//            
//            let fileName = "\(UUID().uuidString).jpg"
//            let filePath = uploadsDir + "/\(fileName)"
//            
//            try await req.fileio.writeFile(byteBuffer, at: filePath)
//            
//            imageURLs.append("/pets/\(fileName)")
//        }
//        
//        guard let userShelterID = user.shelterID else {
//            throw Abort(.notFound, reason: "User shelter ID Not found")
//        }
//        
//        guard let userShelter = try await Shelter.query(on: req.db)
//            .filter(\Shelter.$id == userShelterID)
//            .first() else {
//            throw Abort(.notFound, reason: "User Shelter Not found")
//        }
//        
//        do {
//            let dbPet = Pet(
//                shelterID: userShelterID,
//                name: petFormData.name,
//                age: petFormData.age,
//                description: petFormData.description,
//                personality: petFormData.personality,
//                idealHome: petFormData.idealHome,
//                medicalCondition: petFormData.medicalCondition,
//                adoptionInfo: petFormData.adoptionInfo,
//                species: petFormData.species,
//                breed: petFormData.breed,
//                size: petFormData.size,
//                gender: petFormData.gender,
//                adoptionStatus: petFormData.adoptionStatus,
//                imageURLs: imageURLs,
//                latitude: userShelter.latitude,
//                longitude: userShelter.longitude,
//                location: nil
//            )
//            
//            try await dbPet.save(on: req.db)
//            
//            guard let sqlDb = req.db as? SQLDatabase else {
//                    throw Abort(.internalServerError, reason: "SQLDatabase no accesible.")
//                }
//
//            let locationString = "SRID=4326;POINT(\(dbPet.longitude) \(dbPet.latitude))"
//
//            try await sqlDb.raw("""
//                UPDATE pets SET location = ST_GeogFromText(\(bind: locationString))
//                WHERE id = \(bind: dbPet.requireID())
//            """).run()
//            
//            print("ACABO PET: \(Date.now)")
//            
//            return .created
//        } catch {
//            print(String(reflecting: error))
//            throw Abort(.badRequest, reason: "Cannot create new pet for shelter \(userShelter.name)")
//        }
//    }
    
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
    
    //EXPLAIN PLANS
    
    @Sendable
    func getPetsByDistance(req: Request) async throws -> Page<PetResponseModel> {
        guard let userLat = req.query[Double.self, at: "lat"],
              let userLon = req.query[Double.self, at: "lon"] else {
            throw Abort(.badRequest, reason: "Se requieren los parámetros 'lat' y 'lon'.")
        }

        let radius: Double = req.query[Double.self, at: "radius"] ?? 3000000
        let page = req.query[Int.self, at: "page"] ?? 1
        let per = req.query[Int.self, at: "per"] ?? 20
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
    func getPetsBySpecie(req: Request) async throws -> Page<PetResponseModel> {
        guard let specieString = req.parameters.get("specie", as: String.self),
              let specieEnum = Species(rawValue: specieString) else {
            throw Abort(.badRequest, reason: "Specie type not found or invalid")
        }
        
        guard let userLat = req.query[Double.self, at: "lat"],
              let userLon = req.query[Double.self, at: "lon"] else {
            throw Abort(.badRequest, reason: "Se requieren los parámetros 'lat' y 'lon'.")
        }

        let radius: Double = req.query[Double.self, at: "radius"] ?? 3000000
        let page = req.query[Int.self, at: "page"] ?? 1
        let per = req.query[Int.self, at: "per"] ?? 20
        let offset = (page - 1) * per

        guard let sqlDb = req.db as? SQLDatabase else {
            throw Abort(.internalServerError, reason: "No se pudo acceder a SQLDatabase.")
        }

        let countQuery = SQLQueryString("""
            SELECT COUNT(*) AS total
            FROM pets
            WHERE ST_DWithin(pets.location, ST_MakePoint(\(literal: userLon), \(literal: userLat))::geography, \(literal: radius))
              AND pets.species = \(literal: specieEnum.rawValue)
        """)
        
        struct CountResult: Decodable { let total: Int }
        let count = try await sqlDb.raw(countQuery).first(decoding: CountResult.self)?.total ?? 0

        let sql = SQLQueryString("""
            SELECT pets.*, ST_Distance(pets.location, ST_MakePoint(\(literal: userLon), \(literal: userLat))::geography) AS distance
            FROM pets
            WHERE ST_DWithin(pets.location, ST_MakePoint(\(literal: userLon), \(literal: userLat))::geography, \(literal: radius))
              AND pets.species = \(literal: specieEnum.rawValue)
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
    func getPetsFromShelter(req: Request) async throws -> [PetResponseModel] {
        let user = try req.auth.require(User.self)
        
        guard let userShelterID = user.shelterID else { throw Abort(.notFound, reason: "Shelter ID not found")}
        
        do {
            return try await Pet.query(on: req.db)
                .filter(\Pet.$shelter.$id == userShelterID)
                .all()
                .map {
                    PetResponseModel(
                        id: $0.id,
                        shelterID: $0.$shelter.id,
                        name: $0.name,
                        age: $0.age,
                        description: $0.description,
                        personality: $0.personality,
                        idealHome: $0.idealHome,
                        medicalCondition: $0.medicalCondition,
                        adoptionInfo: $0.adoptionInfo,
                        species: $0.species,
                        breed: $0.breed,
                        size: $0.size,
                        gender: $0.gender,
                        adoptionStatus: $0.adoptionStatus,
                        imageURLs: $0.imageURLs,
                        distance: 0.0
                    )
                }
        } catch {
            throw Abort(.notFound, reason: "Cannot get all Pets From Shelter: \(error)")
        }
    }
    
    @Sendable
    func getPetsFromShelterByID(req: Request) async throws -> [PetResponseModel] {
        guard let shelterID = req.parameters.get("shelterID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid shelterID")
        }
        
        do {
            return try await Pet.query(on: req.db)
                .filter(\Pet.$shelter.$id == shelterID)
                .all()
                .map {
                    PetResponseModel(
                        id: $0.id,
                        shelterID: $0.$shelter.id,
                        name: $0.name,
                        age: $0.age,
                        description: $0.description,
                        personality: $0.personality,
                        idealHome: $0.idealHome,
                        medicalCondition: $0.medicalCondition,
                        adoptionInfo: $0.adoptionInfo,
                        species: $0.species,
                        breed: $0.breed,
                        size: $0.size,
                        gender: $0.gender,
                        adoptionStatus: $0.adoptionStatus,
                        imageURLs: $0.imageURLs,
                        distance: 0.0
                    )
                }
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
    let images: [String]
    
    let size: PetSize
    let adoptionStatus: AdoptionStatus
    let species: Species
    let gender: PetGender
}

struct PetResponseModel: Content {
    let id: UUID?
    let shelterID: UUID?
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
