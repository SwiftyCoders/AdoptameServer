import Vapor
import Fluent

struct SheltersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let shelters = routes.grouped("shelters")
        shelters.get(use: getAllShelters) // GET /shelters
        shelters.get(":id", use: getShelterByID) // GET /shelters/:id
        shelters.post(use: createShelter) // POST /shelters
        //shelters.put(":id", use: replaceShelter) // PUT /shelters/:id
        shelters.patch(":id", use: updateShelter) // PATCH /shelters/:id
        //shelters.get(":id/pets", use: getAllPetsFromShelter) // GET /shelters/:id/pets
        shelters.delete(":id", use: deleteShelter) // DELETE /shelters/:id
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
        //let user = try req.auth.require(User.self)
        guard let userOne = try await User.query(on: req.db)
            .first() else { throw Abort(.badRequest) }
        
        let newShelter = try req.content.decode(ShelterDTO.self)
        
        let fileName = "\(UUID().uuidString).jpg"
        let filePath = "Public/uploads/\(fileName)"
        let fileURLPath = "uploads/\(fileName)"
        
        guard let imageBase64 = newShelter.image else {
            throw Abort(.badRequest, reason: "Image is required")
        }

        let base64String = imageBase64.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
        
        guard let imageData = Data(base64Encoded: base64String) else {
            throw Abort(.badRequest, reason: "Invalid image data")
        }
        
        try FileManager.default.createDirectory(
                atPath: "Public/uploads",
                withIntermediateDirectories: true,
                attributes: nil
            )
                
        try await req.fileio.writeFile(
                ByteBuffer(data: imageData),
                at: filePath
        )
        
        let finalShelter = Shelter(name: newShelter.name, contactEmail: newShelter.contactEmail, latitude: newShelter.latitude, longitude: newShelter.longitude, imageURL: fileURLPath)
        
        do {
            try await finalShelter.save(on: req.db)
            userOne.$shelter.id = finalShelter.id
            try await userOne.save(on: req.db)
            
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
            .filter(\.$id == id)
            .first() else {
            throw Abort(.notFound, reason: "Not shelter found with this ID")
            }
        
        if let imageURL = shelter.imageURL {
            let filePath = "\(imageURL)"
            print(filePath)
            try FileManager.default.removeItem(atPath: filePath)
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
                .filter(\.$shelter.$id == shelterID)
                .all()
        } catch {
            throw Abort(.notFound, reason: "Not pets found on \(user.name) shelter")
        }
    }
}
