import Vapor
import JWT
import Fluent

struct SheltersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let shelters = routes.grouped("shelters")
        let tokenProtected = shelters.grouped(UserAuthenticator())
        //change to protected if works
        tokenProtected.on(.POST, body: .collect(maxSize: "10mb"), use: createShelter)
        
        shelters.get(use: getAllShelters)
        shelters.get(":id", use: getShelterByID)
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
    
    /*
     @Sendable
     func createShelter(req: Request) async throws -> HTTPStatus {
     let user = try req.auth.require(User.self)
     
     if user.shelterID != nil {
     throw Abort(.conflict, reason: "User already has a shelter assigned")
     }
     
     // En vez de verificar el contentType, intentamos decodificar directamente
     // Creamos un struct temporal para manejar los campos del formulario
     struct FormData: Content {
     let name: String
     let contactEmail: String
     let latitude: Double
     let longitude: Double
     let description: String?
     let adoptionPolicy: String?
     let phone: String?
     let website: String?
     let address: String?
     }
     
     // Decodificamos los campos del formulario
     let formData = try req.content.decode(FormData.self)
     
     // Procesamos la imagen si existe
     var imageURLPath: String? = nil
     
     if let image = req.body.data {
     // Crear el directorio si no existe
     try FileManager.default.createDirectory(
     atPath: "Public/uploads",
     withIntermediateDirectories: true,
     attributes: nil
     )
     
     let fileName = "\(UUID().uuidString).jpg"
     let filePath = "Public/uploads/\(fileName)"
     imageURLPath = "uploads/\(fileName)"
     
     try await req.fileio.writeFile(
     image,
     at: filePath
     )
     }
     
     let finalShelter = Shelter(
     name: formData.name,
     contactEmail: formData.description ?? "",
     latitude: formData.latitude,
     longitude: formData.longitude,
     ownerID: user.id!,
     phone: formData.phone ?? "",
     address: formData.address ?? "",
     websiteURL: formData.website ?? "",
     imageURL: imageURLPath,
     description: formData.description ?? ""
     )
     
     do {
     try await finalShelter.save(on: req.db)
     
     user.shelterID = finalShelter.id
     user.role = .shelter
     try await user.save(on: req.db)
     
     return .created
     } catch {
     throw Abort(.notAcceptable, reason: "Cannot create new shelter: \(error)")
     }
     }
     */
    //    @Sendable
    //    func createShelter(req: Request) async throws -> HTTPStatus {
    //        let user = try req.auth.require(User.self)
    //        
    //        if user.shelterID != nil {
    //            throw Abort(.conflict, reason: "User already has a shelter assigned")
    //        }
    //        
    //        let newShelter = try req.content.decode(ShelterDTO.self)
    //        
    //        let fileName = "\(UUID().uuidString).jpg"
    //        let filePath = "Public/uploads/\(fileName)"
    //        let fileURLPath = "uploads/\(fileName)"
    //        
    ////        guard let imageBase64 = newShelter.image else {
    ////            throw Abort(.badRequest, reason: "Image is required")
    ////        }
    ////        
    ////        let base64String = imageBase64.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
    ////        guard let imageData = Data(base64Encoded: base64String) else {
    ////            throw Abort(.badRequest, reason: "Invalid image data")
    ////        }
    ////        
    ////        try FileManager.default.createDirectory(
    ////            atPath: "Public/uploads",
    ////            withIntermediateDirectories: true,
    ////            attributes: nil
    ////        )
    ////        
    ////        try await req.fileio.writeFile(
    ////            ByteBuffer(data: imageData),
    ////            at: filePath
    ////        )
    //        
    ////        let finalShelter = Shelter(
    ////            name: newShelter.name,
    ////            contactEmail: newShelter.contactEmail,
    ////            latitude: newShelter.latitude,
    ////            longitude: newShelter.longitude,
    ////            ownerID: user.id!,
    ////            imageURL: fileURLPath
    ////        )
    //        
    //        let finalShelter = Shelter(
    //            name: newShelter.name,
    //            contactEmail: newShelter.contactEmail,
    //            latitude: newShelter.latitude,
    //            longitude: newShelter.longitude,
    //            ownerID: user.id!
    //        )
    //        
    //        do {
    //            try await finalShelter.save(on: req.db)
    //            
    //            user.shelterID = finalShelter.id
    //            user.role = .shelter
    //            try await user.save(on: req.db)
    //            
    //            return .created
    //        } catch {
    //            throw Abort(.notAcceptable, reason: "Cannot create new shelter")
    //        }
    //    }
    
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
    
    @Sendable
    func createShelter(req: Request) async throws -> HTTPStatus {
        // Log básico del inicio de la solicitud
        print("🔵 Iniciando procesamiento de createShelter")
        
        // Verificar el token y autenticación
        print("🔐 Verificando autenticación...")
        let user = try req.auth.require(User.self)
        print("✅ Usuario autenticado: \(user.email ?? "sin email")")
        
        if user.shelterID != nil {
            print("⚠️ Usuario ya tiene un shelter asignado")
            throw Abort(.conflict, reason: "User already has a shelter assigned")
        }
        
        // Inspeccionar los headers
        print("📋 Headers de la solicitud:")
        for header in req.headers {
            print("  \(header.name): \(header.value)")
        }
        
        // Verificar el tipo de contenido
        print("📄 Content-Type: \(req.headers.first(name: .contentType) ?? "No content type")")
        
        // Intentar decodificar el formulario
        print("🔍 Intentando decodificar el formulario multipart...")
        do {
            let formData = try req.content.decode(ShelterFormData.self, as: .formData)
            print("✅ Formulario decodificado correctamente")
            print("📝 Nombre del shelter: \(formData.name)")
            print("📝 Tamaño de la imagen: \(formData.image?.count ?? 0) bytes")
            
            // Procesar la imagen si existe
            var imageURLPath: String? = nil
            
            if let imageFile = formData.image {
                print("🖼️ Procesando imagen de \(imageFile.count) bytes")
                try FileManager.default.createDirectory(
                    atPath: "Public/uploads",
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                
                let fileName = "\(UUID().uuidString).jpg"
                let filePath = "Public/uploads/\(fileName)"
                imageURLPath = "uploads/\(fileName)"
                
                print("💾 Guardando imagen en: \(filePath)")
                try await req.fileio.writeFile(
                    ByteBuffer(data: imageFile),
                    at: filePath
                )
                print("✅ Imagen guardada correctamente")
            } else {
                print("⚠️ No se recibió imagen")
            }
            
            print("🏗️ Creando objeto Shelter...")
            let finalShelter = Shelter(
                name: formData.name,
                contactEmail: formData.contactEmail,
                latitude: formData.latitude,
                longitude: formData.longitude,
                ownerID: user.id!,
                phone: formData.phone ?? "",
                address: formData.address ?? "",
                websiteURL: formData.website ?? "",
                imageURL: imageURLPath,
                description: formData.description ?? ""
            )
            
            print("💾 Guardando shelter en la base de datos...")
            try await finalShelter.save(on: req.db)
            
            print("🔄 Actualizando información del usuario...")
            user.shelterID = finalShelter.id
            user.role = .shelter
            try await user.save(on: req.db)
            
            print("✅ Shelter creado exitosamente")
            return .created
        } catch {
            print("❌ Error al decodificar o procesar el formulario: \(error)")
            print("❌ Error detallado: \(error.localizedDescription)")
            
            // Intenta diagnosticar problemas específicos
            if let abortError = error as? Abort {
                print("❌ Abort error: \(abortError.reason)")
            }
            
            // Si el error es en la decodificación, veamos qué datos estamos recibiendo
            print("🔍 Intentando examinar los datos en bruto...")
            if let bodyData = req.body.data {
                print("📦 Tamaño de los datos en bruto: \(bodyData.readableBytes) bytes")
                
                // Guardar los datos para examinarlos
                do {
                    let fileName = "error_payload_\(Date().timeIntervalSince1970).raw"
                    let filePath = "Public/debug/\(fileName)"
                    
                    // Crear directorio de depuración
                    try FileManager.default.createDirectory(
                        atPath: "Public/debug",
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                    
                    print("💾 Guardando payload de error en: \(filePath)")
                    try await req.fileio.writeFile(bodyData, at: filePath)
                    print("✅ Payload guardado para depuración")
                } catch {
                    print("❌ No se pudo guardar el payload: \(error)")
                }
            } else {
                print("❌ No hay datos en el cuerpo de la solicitud")
            }
            
            throw Abort(.notAcceptable, reason: "Cannot create new shelter: \(error)")
        }
    }
}
    
//    @Sendable
//    func createShelter(req: Request) async throws -> HTTPStatus {
//        let user = try req.auth.require(User.self)
//        
//        if user.shelterID != nil {
//            throw Abort(.conflict, reason: "User already has a shelter assigned")
//        }
//        
//        let formData = try req.content.decode(ShelterFormData.self, as: .formData)
//        
//        var imageURLPath: String? = nil
//        
//        if let imageFile = formData.image {
//            try FileManager.default.createDirectory(
//                atPath: "Public/uploads",
//                withIntermediateDirectories: true,
//                attributes: nil
//            )
//            
//            let fileName = "\(UUID().uuidString).jpg"
//            let filePath = "Public/uploads/\(fileName)"
//            imageURLPath = "uploads/\(fileName)"
//            
//            try await req.fileio.writeFile(
//                ByteBuffer(data: imageFile),
//                at: filePath
//            )
//        }
//        
//        let finalShelter = Shelter(
//            name: formData.name,
//            contactEmail: formData.contactEmail,  // Asegúrate de usar el campo correcto
//            latitude: formData.latitude,
//            longitude: formData.longitude,
//            ownerID: user.id!,
//            phone: formData.phone ?? "",
//            address: formData.address ?? "",
//            websiteURL: formData.website ?? "",
//            imageURL: imageURLPath,
//            description: formData.description ?? ""
//        )
//        
//        do {
//            try await finalShelter.save(on: req.db)
//            
//            user.shelterID = finalShelter.id
//            user.role = .shelter
//            try await user.save(on: req.db)
//            
//            return .created
//        } catch {
//            throw Abort(.notAcceptable, reason: "Cannot create new shelter: \(error)")
//        }
//    }
//}

struct ShelterFormData: Content {
    let name: String
    let contactEmail: String
    let latitude: Double
    let longitude: Double
    let description: String?
    let adoptionPolicy: String?
    let phone: String?
    let website: String?
    let address: String?
    let image: Data?  // Aquí se decodifica el archivo de imagen
}
