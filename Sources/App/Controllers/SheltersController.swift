import Vapor
import Fluent

struct SheltersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let shelters = routes.grouped("shelters")
        shelters.get(use: getAllShelters)
        shelters.get(":id", use: getShelterByID)
        shelters.post(use: createShelter)
        shelters.put(":id", use: updateShelter)
    }
    
    @Sendable
    func getAllShelters(req: Request) async throws -> [Shelter] {
        return try await Shelter.query(on: req.db)
            .all()
    }
    
    @Sendable
    func getShelterByID(req: Request) async throws -> Shelter {
        guard let shelter = try await Shelter.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound, reason: "Shelter not found")
        }
        
        return shelter
    }
    
    @Sendable
    func createShelter(req: Request) async throws -> HTTPStatus {
        let newShelter = try req.content.decode(Shelter.self)
        
        do {
            try await newShelter.save(on: req.db)
            return .created
        } catch {
            throw Abort(.notAcceptable, reason: "cannot create new shelter")
        }
    }
    
    @Sendable
    func updateShelter(req: Request) async throws -> Shelter {
            let user = try req.auth.require(User.self)
            
            guard user.role == .shelter, let shelterID = user.$shelter.id else {
                throw Abort(.forbidden, reason: "Only shelters can update their profile")
            }

            guard let shelter = try await Shelter.find(shelterID, on: req.db) else {
                throw Abort(.notFound, reason: "Shelter not found")
            }

            let updatedShelter = try req.content.decode(Shelter.self)
            shelter.name = updatedShelter.name
            shelter.contactEmail = updatedShelter.contactEmail
            shelter.phone = updatedShelter.phone
            shelter.address = updatedShelter.address
            shelter.latitude = updatedShelter.latitude
            shelter.longitude = updatedShelter.longitude
            shelter.websiteURL = updatedShelter.websiteURL
            shelter.imageURL = updatedShelter.imageURL
            shelter.description = updatedShelter.description

            try await shelter.save(on: req.db)
            return shelter
        }
}
