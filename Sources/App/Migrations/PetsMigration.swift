import Fluent

struct PetsMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Pet.schema)
            .id()
            .field(.name, .string, .required)
            .field(.accessKey, .uuid, .required)
            .field(.age, .string, .required)
            .field(.breed, .string)
            .field(.summary, .string)
            .field(.type, .string)
            .field(.size, .string)
            .field(.status, .string)
            .field(.color, .string)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Pet.schema).delete()
    }
}
