import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: AuthController())
    
    //let protectedRoutes = app.grouped(JWTMiddleware())
    try app.register(collection: PetsController())
    try app.register(collection: SheltersController())
}
