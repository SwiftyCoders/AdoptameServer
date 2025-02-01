import Vapor
import JWT

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authRoute = routes.grouped("auth")
        authRoute.post("apple", use: signInWithApple)
    }
    
    @Sendable
    func signInWithApple(req: Request) async throws -> TokenResponse {
        let authRequest = try req.content.decode(AppleAuthRequest.self)
        
        do {
            guard let keys = req.application.storage[JWTKeysStorageKey.self] else {
                throw Abort(.internalServerError, reason: "JWTKeyCollection no configurada")
            }
                        
            let appleJWT = try await req.jwt.apple.verify(authRequest.identityToken)
            
            print("✅ Token válido. Apple User ID: \(appleJWT.subject)")
            
            let appleUserID = appleJWT.subject
                                    
            let userArray = try await User.query(on: req.db)
                .all()
            
            var user = userArray.filter( { $0.appleUserID == appleUserID.value } ).first
                        
            if user == nil {
                user = User(appleUserID: appleUserID.value, name: "", email: appleJWT.email ?? "", role: .adopter)
                try? await user?.save(on: req.db)
            }
            
            guard let authenticatedUser = user else {
                throw Abort(.internalServerError, reason: "User creation failed")
            }
            
            let payload = AuthPayload(
                sub: SubjectClaim(value: try authenticatedUser.requireID().uuidString),
                exp: .init(value: .distantFuture)
            )
            
            let token = try await keys.sign(payload)
            print("TOKEN: \(token)")
            return TokenResponse(token: token)
        } catch {
            throw Abort(.unauthorized)
        }
    }
    
    @Sendable
    func getUser(req: Request) async throws -> User {
        return try req.auth.require(User.self)
    }
    
    private func fetchAppleJWKS(_ req: Request) async throws -> JWKS {
        let jwksURL = URI(string: "https://appleid.apple.com/auth/keys")
        let response = try await req.client.get(jwksURL)
        
        guard response.status == .ok else {
            throw Abort(.internalServerError, reason: "No se pudieron obtener las claves de Apple")
        }
        
        return try response.content.decode(JWKS.self)
    }
}

struct AppleAuthRequest: Content {
    let identityToken: String
}

struct TokenResponse: Content {
    let token: String
}

struct AuthPayload: JWTPayload {
    var sub: SubjectClaim
    var exp: ExpirationClaim

    func verify(using key: some JWTAlgorithm) throws {
        try self.exp.verifyNotExpired()
    }
}
