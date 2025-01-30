import Vapor
import Fluent

struct SheltersMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Shelter.schema)
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
                .field("createdAt", .datetime)
                .field("updatedAt", .datetime)
                .unique(on: "contactEmail")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(Shelter.schema).delete()
        }
}
