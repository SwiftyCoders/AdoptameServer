import Fluent
import Vapor

func routes(_ app: Application) throws {
    let authController = AuthController()
    
    let protectedRoutes = app.grouped(MockAuthMiddleware())
    
    try protectedRoutes.register(collection: authController)
    try protectedRoutes.register(collection: PetsController())
    try protectedRoutes.register(collection: SheltersController())
}
