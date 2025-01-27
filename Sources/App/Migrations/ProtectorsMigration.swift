//
//  File.swift
//  Rescatame
//
//  Created by Alberto Alegre Bravo on 27/1/25.
//

import Vapor
import Fluent

struct ProtectorsMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Protector.schema)
            .id()
            .field("name", .string, .required)
            .field("address", .string, .required)
            .field("latitude", .double, .required)
            .field("longitude", .double, .required)
            .field("email", .string, .required)
            .field("phone", .string, .required)
            .field("website", .string)
            .field("code", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Protector.schema).delete()
    }
}
