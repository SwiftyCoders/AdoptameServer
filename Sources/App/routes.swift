import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: AuthController())
    
    let protectedRoutes = app.grouped(JWTMiddleware())
    try protectedRoutes.register(collection: PetsController())
    try protectedRoutes.register(collection: SheltersController())
}
