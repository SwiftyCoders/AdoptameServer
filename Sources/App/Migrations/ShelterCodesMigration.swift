import Vapor
import Fluent

struct ShelterCodesMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(ShelterCode.schema)
                .id()
                .field("code", .string, .required)
                .field("shelterName", .string, .required)
                .field("createdAt", .datetime)
                .unique(on: "code")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(ShelterCode.schema).delete()
        }
}
