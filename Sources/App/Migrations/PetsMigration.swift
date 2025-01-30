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
                    .field("shelterID", .uuid, .required, .references("shelters", "id", onDelete: .cascade))
                    .field("name", .string, .required)
                    .field("age", .int)
                    .field("description", .string, .required)
                    .field("species", petType, .required)
                    .field("breed", .string)
                    .field("weight", .double)
                    .field("size", petSize, .required)
                    .field("adoptionStatus", .string, .required)
                    .field("imageURLs", .array(of: .string))
                    .field("latitude", .double, .required)
                    .field("longitude", .double, .required)
                    .field("createdAt", .datetime)
                    .field("updatedAt", .datetime)
                    .create()
            }

            func revert(on database: Database) async throws {
                try await database.schema(Pet.schema).delete()
                try await database.enum("pet_type").delete()
                try await database.enum("pet_size").delete()
            }
}
