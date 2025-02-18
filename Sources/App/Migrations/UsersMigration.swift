import Fluent

//struct UsersMigration: AsyncMigration {
//    func prepare(on database: Database) async throws {
//        try await database.schema(User.schema)
//            .id()
//            .field("appleUserID", .string, .required)
//            .field("name", .string, .required)
//            .field("email", .string)
//            .field("role", .string, .required)
//            .field("shelterID", .uuid, .references("shelters", "id", onDelete: .cascade))
//            .field("createdAt", .datetime)
//            .field("updatedAt", .datetime)
//            .unique(on: "email")
//            .unique(on: "appleUserID")
//            .create()
//    }
//
//    func revert(on database: Database) async throws {
//        try await database.schema(User.schema).delete()
//    }
//}

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
