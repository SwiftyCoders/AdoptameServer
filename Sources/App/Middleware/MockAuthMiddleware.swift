import Vapor
import Foundation
import JWT

struct JWTMiddleware: AsyncBearerAuthenticator {
   
    
//    func respond(to req: Request, chainingTo next: AsyncResponder) async throws -> Response {
//        guard let token = req.headers.bearerAuthorization?.token else {
//            throw Abort(.unauthorized, reason: "Falta el token de autenticación")
//        }
//
//        do {
//            guard let keys = req.application.storage[JWTKeysStorageKey.self] else {
//                throw Abort(.internalServerError, reason: "JWTKeyCollection no configurada")
//            }
//            
//            let payload = try await keys.verify(token, as: ExamplePayload.self)
//
//            guard let userID = UUID(uuidString: payload.sub.value),
//                  let user = try await User.find(userID, on: req.db) else {
//                throw Abort(.unauthorized, reason: "Usuario no encontrado")
//            }
//            
//            req.auth.login(user)
//
//            return try await next.respond(to: req)
//        } catch {
//            throw Abort(.unauthorized, reason: "Token inválido")
//        }
//    }
    
    func authenticate(bearer: BearerAuthorization, for req: Request) async throws {
            guard let keys = req.application.storage[JWTKeysStorageKey.self] else {
                throw Abort(.internalServerError, reason: "JWTKeyCollection no configurada")
            }

            do {
                // 🔹 Verificar el token y extraer el userID
                let payload = try await keys.verify(bearer.token, as: ExamplePayload.self)

                guard let userID = UUID(uuidString: payload.sub.value),
                      let user = try await User.find(userID, on: req.db) else {
                    throw Abort(.unauthorized, reason: "Usuario no encontrado")
                }

                // 🔹 Guardar el usuario autenticado en `req.auth`
                req.auth.login(user)

            } catch {
                throw Abort(.unauthorized, reason: "Token inválido")
            }
        }
}
