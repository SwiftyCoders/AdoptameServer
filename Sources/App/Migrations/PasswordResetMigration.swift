import Vapor
import Fluent

struct PasswordResetMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(PasswordResetToken.schema)
            .id()
            .field("token", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("expires_at", .datetime, .required)
            .field("used", .bool, .required)
            .unique(on: "token")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(PasswordResetToken.schema).delete()
    }
}
