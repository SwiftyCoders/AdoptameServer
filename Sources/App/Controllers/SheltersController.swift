import Vapor
import Fluent

struct SheltersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let shelters = routes.grouped("shelters")
        shelters.get(use: getAllShelters)
        shelters.get(":id", use: getShelterByID)
        shelters.post(use: createShelter)
        shelters.put(":id", use: updateShelter)
        shelters.get("allPets", use: getAllPetsFromShelter)
        shelters.delete(":id", use: deleteShelter)
    }
    
    @Sendable
    func getAllShelters(req: Request) async throws -> [Shelter] {
         do {
            return try await Shelter.query(on: req.db)
                .all()
         } catch {
             return []
         }
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
        let user = try req.auth.require(User.self)
        
        do {
            try await newShelter.save(on: req.db)
            
            //vincular el shelterID creado -> User
            
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
    
    @Sendable
    func deleteShelter(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "cannot find shelter ID")
        }
        
        guard let shelter = try await Shelter.query(on: req.db)
            .filter(\Shelter.$id == id)
            .first() else {
            throw Abort(.notFound, reason: "Not shelter found with this ID")
            }
        
        do {
            try await shelter.delete(on: req.db)
            return .ok
        } catch {
            throw Abort(.badRequest, reason: "Cannot delete this shelter from DB")
        }
    }
    
    @Sendable
    func getAllPetsFromShelter(req: Request) async throws -> [Pet] {
        let user = try req.auth.require(User.self)
        
        guard let shelterID = user.$shelter.id else {
            throw Abort(.notFound, reason: "Shelter ID not valid")
        }
        
        do {
            return try await Pet.query(on: req.db)
                .filter(\Pet.$shelter.$id == shelterID)
                .all()
        } catch {
            throw Abort(.notFound, reason: "Not pets found on \(user.name) shelter")
        }
    }
}
