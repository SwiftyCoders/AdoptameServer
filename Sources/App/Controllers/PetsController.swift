import Fluent
import Vapor

struct PetsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let pets = routes.grouped("pets")
        pets.get(use: getAllPets)
        pets.delete(":petID", use: deletePet)
        
        //TODO: Shelter or Pet Controller?
        pets.post("newPet", use: addPet)
        
    }
    
    @Sendable
    func getAllPets(req: Request) async throws -> [Pet] {
        do {
            return try await Pet.query(on: req.db)
                .all()
        } catch {
            return []
        }
    }
    
    @Sendable
    func addPet(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self) //PACO -> AMIGO ANIMAL
        
        let pet = try req.content.decode(PetDTO.self) // Luna
        
        //guard let userID = user.id else { throw Abort(.notFound, reason: "UserID Not found")}
        
        let userShelter = try await User.query(on: req.db)
            .filter(\User.$id == UUID(uuidString: "e35be625-06c2-4425-87de-c9ec197cb9e6")!)
            .with(\.$shelter)
            .first()
                
        guard let user = userShelter,
              let shelterID = user.shelter?.id else {
            throw Abort(.notFound, reason: "ShelterID not found")
        }
        
        do {
            let dbPet = Pet(
                shelterID: shelterID,
                name: pet.name,
                description: pet.description,
                species: pet.species,
                size: pet.size,
                adoptionStatus: pet.adoptionStatus,
                latitude: pet.longitude,
                longitude: pet.latitude
            )
            
            try await dbPet.save(on: req.db)
            return .created
        } catch {
            throw Abort(.notFound)
        }
        
    }
    
    @Sendable
    func deletePet(req: Request) async throws -> HTTPStatus {
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
        .ok
    }
}

struct PetDTO: Content {
    var name: String
    var age: Int?
    var description: String
    var species: Species
    var breed: String?
    var weight: Double?
    var size: PetSize
    var adoptionStatus: AdoptionStatus
    var imageURLs: [String]?
    var latitude: Double
    var longitude: Double
}
