import Vapor

struct MockAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let mockUser = User(id: UUID(),name: "test user", email: "testUser@gmail.com", role: .shelter)
        
        request.auth.login(mockUser)
        
        return try await next.respond(to: request)
    }
}
