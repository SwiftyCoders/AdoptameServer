//
//  File.swift
//  Rescatame
//
//  Created by Alberto Alegre Bravo on 27/1/25.
//

import Vapor
import Fluent

final class Protector: Model, Content, @unchecked Sendable {
    static let schema = "protectors"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "address")
    var address: String
    
    @Field(key: "latitude")
    var latitude: Double
    
    @Field(key: "longitude")
    var longitude: Double
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "phone")
    var phone: String
    
    @Field(key: "website")
    var website: String?
    
    @Field(key: "code")
    var code: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Children(for: \.$protectora)
    var mascotas: [Pet]
    
    init() {}
    
    init(id: UUID? = nil, name: String, address: String, latitude: Double, longitude: Double, email: String, phone: String, website: String? = nil, code: String) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.email = email
        self.phone = phone
        self.website = website
        self.code = code
    }
}
