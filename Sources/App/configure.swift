import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

public func configure(_ app: Application) async throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    if let databaseURL = Environment.get("DATABASE_URL") {
        app.databases.use(try .postgres(url: databaseURL), as: .psql)
    } else {
        fatalError("DATABASE_URL is not set")
    }

    app.migrations.add(PetsMigration())

    app.views.use(.leaf)

    try routes(app)
}
