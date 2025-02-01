import Vapor
import Foundation
import JWT

struct JWTMiddleware: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for req: Request) async throws {
        guard let keys = req.application.storage[JWTKeysStorageKey.self] else {
            throw Abort(.internalServerError, reason: "JWTKeyCollection no configurada")
        }
        
        do {
            let payload = try await keys.verify(bearer.token, as: AuthPayload.self)
            
            //            guard let userID = UUID(uuidString: payload.sub.value),
            //                  let user = try await User.find(userID, on: req.db) else {
            //                throw Abort(.unauthorized, reason: "Usuario no encontrado")
            //            }
            
            let userID = UUID(uuidString: payload.sub.value)
            
            guard let user = try await User.query(on: req.db)
                .filter(.id, .equal, userID)
                .first() else {
                throw Abort(.unauthorized, reason: "Usuario no encontrado")
            }
            
            req.auth.login(user)
        } catch {
            throw Abort(.unauthorized, reason: "Token inválido")
        }
    }
}
