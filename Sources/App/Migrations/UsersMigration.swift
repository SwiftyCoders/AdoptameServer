import Fluent

struct UsersMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("appleUserID", .string, .required)
            .field("name", .string, .required)
            .field("email", .string)
            .field("password", .string, .required)
            .field("role", .string, .required)
            .field("shelterID", .uuid)
            .field("createdAt", .datetime)
            .field("updatedAt", .datetime)
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}

struct UserTokensMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(UserToken.schema)
            .id()
            .field("value", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("created_at", .datetime, .required)
            .unique(on: "value")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(UserToken.schema).delete()
    }
}
