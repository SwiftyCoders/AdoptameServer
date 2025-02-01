import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
import JWT

public func configure(_ app: Application) async throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
        
    let secretKey = Environment.get("JWT_SECRET") ?? "ESTA_ES_MI_CLAVE_SECRETA"

    let keys = JWTKeyCollection()
    let hkey = HMACKey(stringLiteral: secretKey)
    await keys.add(hmac: hkey, digestAlgorithm: .sha256)

    await app.storage.setWithAsyncShutdown(JWTKeysStorageKey.self, to: keys)
    
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

struct JWTKeysStorageKey: StorageKey {
    typealias Value = JWTKeyCollection
}
