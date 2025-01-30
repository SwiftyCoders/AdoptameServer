import Vapor

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authRoute = routes.grouped("auth")
        authRoute.get("me", use: getUser)
    }
    
    @Sendable
    func getUser(req: Request) async throws -> User {
        return try req.auth.require(User.self)
    }
}
