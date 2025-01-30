import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

public func configure(_ app: Application) async throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(MockAuthMiddleware())

    if let databaseURL = Environment.get("DATABASE_URL") {
        app.databases.use(try .postgres(url: databaseURL), as: .psql)
    } else {
        fatalError("DATABASE_URL is not set")
    }

    app.migrations.add(ShelterCodesMigration())
    app.migrations.add(SheltersMigration())
    app.migrations.add(UsersMigration())
    app.migrations.add(PetsMigration())

    app.views.use(.leaf)

    try routes(app)
}
