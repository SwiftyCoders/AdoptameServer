import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
import JWT

public func configure(_ app: Application) async throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    guard let secretKey = Environment.get("JWT_SECRET") else {
        app.logger.critical("JWT_SECRET is not set in environment variables")
        throw Abort(.internalServerError, reason: "Database not configured VARIABLES.")
    }
    
    let keys = JWTKeyCollection()
    let hkey = HMACKey(stringLiteral: secretKey)
    await keys.add(hmac: hkey, digestAlgorithm: .sha256)

    await app.storage.setWithAsyncShutdown(JWTKeysStorageKey.self, to: keys)
    
    if let databaseURL = Environment.get("DATABASE_URL") {
        app.databases.use(try .postgres(url: databaseURL), as: .psql)
    } else {
        app.logger.critical("DATABASE_URL is not set. Server cannot start.")
        throw Abort(.internalServerError, reason: "Database not configured.")
    }

    app.migrations.add(ShelterCodesMigration())
    app.migrations.add(SheltersMigration())
    app.migrations.add(UsersMigration())
    app.migrations.add(PetsMigration())

    app.views.use(.leaf)

    try routes(app)
}

struct JWTKeysStorageKey: StorageKey {
    typealias Value = JWTKeyCollection
}
