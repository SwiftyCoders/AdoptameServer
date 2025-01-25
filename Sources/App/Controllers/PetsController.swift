import Fluent
import Vapor

struct PetsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let pets = routes.grouped("api", "pets")
        pets.get(use: getAllPets)
        pets.post("newPet", use: addPet)
        pets.delete(":petID", use: deletePet)
        
    }

    @Sendable
    func getAllPets(req: Request) async throws -> [Pet] {
        try await Pet.query(on: req.db)
            .all()
    }

    @Sendable
    func addPet(req: Request) async throws -> HTTPStatus {
        let pet = try req.content.decode(Pet.self)
        do {
            try await pet.create(on: req.db)
            return .created
        } catch {
            throw Abort(.badRequest, reason: "Cannot post new pet")
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
}
