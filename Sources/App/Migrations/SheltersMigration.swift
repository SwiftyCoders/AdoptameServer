import Vapor
import Fluent

struct SheltersMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("shelters")
            .id()
            .field("name", .string, .required)
            .field("contactEmail", .string, .required)
            .field("phone", .string)
            .field("address", .string)
            .field("latitude", .double, .required)
            .field("longitude", .double, .required)
            .field("websiteURL", .string)
            .field("imageURL", .string)
            .field("description", .string)
            .field("ownerID", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("createdAt", .datetime)
            .field("updatedAt", .datetime)
            .field("location", .custom("GEOGRAPHY(POINT, 4326)"))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("shelters").delete()
    }
}
