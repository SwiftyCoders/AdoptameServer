import Fluent
import Vapor
import SQLKit

struct PetsMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Pet.schema)
            .id()
            .field("shelterID", .uuid, .required, .references("shelters", "id"))
            .field("name", .string, .required)
            .field("age", .string)
            .field("description", .string)
            .field("personality", .string)
            .field("idealHome", .string)
            .field("medicalCondition", .string)
            .field("adoptionInfo", .string)
            .field("species", .string, .required)
            .field("breed", .string)
            .field("size", .string, .required)
            .field("gender", .string, .required)
            .field("adoptionStatus", .string, .required)
            .field("imageURLs", .array(of: .string))
            .field("latitude", .double, .required)
            .field("longitude", .double, .required)
            .field("createdAt", .datetime)
            .field("updatedAt", .datetime)
            .field("location", .custom("GEOGRAPHY(POINT, 4326)"))
            .create()
        
//        if let sql = database as? SQLDatabase {
//            try await sql.raw("""
//                CREATE INDEX pets_location_index ON pets USING GIST(location)
//            """).run()
//        }
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Pet.schema).delete()
    }
}
