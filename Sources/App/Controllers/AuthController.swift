import Vapor
import JWT
import Fluent

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authRoute = routes.grouped("auth")
        authRoute.post("create", use: createUser)
        authRoute.post("apple", use: signInWithApple)
        authRoute.post("login", use: loginUser)
    }
    
    @Sendable
    func createUser(req: Request) async throws -> HTTPStatus {
        try User.Create.validate(content: req)
        
        let create = try req.content.decode(User.Create.self)
        let allUsers = try await User.query(on: req.db).all()
        
        if let _ = allUsers.filter( { $0.email == create.email} ).first {
            throw Abort(.badRequest, reason: "User already exists")
        } else {
            let user = User(
                appleUserID: "",
                name: "",
                email: create.email,
                password: try Bcrypt.hash(create.password),
                role: .adopter
            )
            
            try await user.create(on: req.db)
            return .created
        }
    }
    
    @Sendable
    func loginUser(req: Request) async throws -> TokenResponse {
        let loginData = try req.content.decode(LoginRequest.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == loginData.email)
            .first() else {
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }
        
        guard try Bcrypt.verify(loginData.password, created: user.password) else {
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }
        
        guard let keys = req.application.storage[JWTKeysStorageKey.self] else {
            throw Abort(.internalServerError, reason: "JWTKeyCollection no configurada")
        }
        
        guard let userID = user.id else { throw Abort(.unauthorized, reason: "userID not found") }
        
        //caducidad 1 hora
        let payload = UserPayload(userID: userID, exp: .init(value: Date().addingTimeInterval(3600)))
        
        let token = try await keys.sign(payload)
        
        return TokenResponse(token: token)
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
                user = User(appleUserID: appleUserID.value, name: "", email: appleJWT.email ?? "", password: "", role: .adopter)
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
        guard let bearer = req.headers.bearerAuthorization else {
            throw Abort(.unauthorized, reason: "No token provided")
        }

        let payload = try await req.jwt.verify(bearer.token, as: UserPayload.self)
        
        guard let user = try await User.find(payload.userID, on: req.db) else {
            throw Abort(.unauthorized, reason: "Usuario no encontrado")
        }
        req.auth.login(user)
        
        return user
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

struct UserPayload: JWTPayload {
    var userID: UUID
    var exp: ExpirationClaim
    
    func verify(using signer: some JWTAlgorithm) throws {
        try self.exp.verifyNotExpired()
    }
}

struct LoginRequest: Content {
    let email: String
    let password: String
}
