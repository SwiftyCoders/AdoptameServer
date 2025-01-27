import Fluent
import Vapor

struct PetsMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
            let petType = try await database.enum("pet_type")
                .case("dog")
                .case("cat")
                .case("rabbit")
                .case("bird")
                .case("reptile")
                .case("other")
                .create()
            
            let petSize = try await database.enum("pet_size")
                .case("small")
                .case("medium")
                .case("large")
                .create()
            
        try await database.schema(Pet.schema)
                .id()
                .field("name", .string, .required)
                .field("age", .int, .required)
                .field("type", petType, .required)
                .field("size", petSize, .required)
                .field("breed", .string)
                .field("description", .string, .required)
                .field("photo_url", .string, .required)
                .field("status", .string, .required)
                .field("protector_id", .uuid, .required, .references("protectors", "id"))
                .field("created_at", .datetime)
                .field("updated_at", .datetime)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Pet.schema).delete()
            
            try await database.enum("pet_type").delete()
            try await database.enum("pet_size").delete()
        }
}
