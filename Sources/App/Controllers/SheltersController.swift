import Vapor
import JWT
import Fluent

struct SheltersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let shelters = routes.grouped("shelters")
        let tokenProtected = shelters.grouped(UserAuthenticator())
        
        shelters.get(use: getAllShelters)
        shelters.get(":id", use: getShelterByID)
        tokenProtected.post(use: createShelter)
        shelters.patch(":id", use: updateShelter)
        shelters.delete(":id", use: deleteShelter)
        tokenProtected.get("byDistance", use: getSheltersByDistance)
    }
    
    @Sendable
    func getSheltersByDistance(req: Request) async throws -> [Shelter] {
        guard let userLat = req.query[Double.self, at: "lat"],
              let userLon = req.query[Double.self, at: "lon"] else {
            throw Abort(.badRequest, reason: "Se requieren los parámetros 'lat' y 'lon'.")
        }
        
        let radius: Double = req.query[Double.self, at: "radius"] ?? 5000
        
        return try await Shelter.query(on: req.db)
            .all()
            .map { shelter -> (Shelter, Double) in
                let petLat = shelter.latitude
                let petLon = shelter.longitude
                
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
                
                return (shelter, distance)
            }
            .filter { _, distance in
                distance <= radius
            }
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
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
        let user = try req.auth.require(User.self)

           if user.shelterID != nil {
               throw Abort(.conflict, reason: "User already has a shelter assigned")
           }

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

//           let finalShelter = Shelter(
//               name: newShelter.name,
//               contactEmail: newShelter.contactEmail,
//               latitude: newShelter.latitude,
//               longitude: newShelter.longitude,
//               ownerID: user.id!,
//               imageURL: fileURLPath
//           )
        
        let finalShelter = Shelter(
            name: newShelter.name,
            contactEmail: newShelter.contactEmail,
            latitude: newShelter.latitude,
            longitude: newShelter.longitude,
            ownerID: user.id!
        )

           do {
               try await finalShelter.save(on: req.db)

               user.shelterID = finalShelter.id
               user.role = .shelter
               try await user.save(on: req.db)

               return .created
           } catch {
               throw Abort(.notAcceptable, reason: "Cannot create new shelter")
           }
    }
    
    @Sendable
    func updateShelter(req: Request) async throws -> Shelter {
        let user = try req.auth.require(User.self)
        
        guard user.role == .shelter, let shelterID = user.$shelterID.value else {
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
        
        guard let shelterID = user.$shelterID.value else {
            throw Abort(.notFound, reason: "Shelter ID not valid")
        }
        
        do {
            return try await Pet.query(on: req.db)
                .filter(\.$shelter.$id == shelterID ?? UUID())
                .all()
        } catch {
            throw Abort(.notFound, reason: "Not pets found on \(user.name) shelter")
        }
    }
}
