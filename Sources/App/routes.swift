import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get(".well-known", "apple-app-site-association") { req -> Response in
        let path = req.application.directory.resourcesDirectory + "apple-app-site-association"
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/json")
        return Response(status: .ok, headers: headers, body: .init(data: data))
    }
    
    try app.register(collection: AuthController())
    
    //let protectedRoutes = app.grouped(JWTMiddleware())
    try app.register(collection: PetsController())
    try app.register(collection: SheltersController())
}
