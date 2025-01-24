import Fluent

struct PetsMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("pets")
            .id()
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("pets").delete()
    }
}
