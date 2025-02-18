import Vapor
import Fluent

//final class Shelter: Model, Content, @unchecked Sendable {
//    static let schema = "shelters"
//
//    @ID(key: .id)
//    var id: UUID?
//
//    @Field(key: "name")
//    var name: String
//
//    @Field(key: "contactEmail")
//    var contactEmail: String
//
//    @OptionalField(key: "phone")
//    var phone: String?
//
//    @OptionalField(key: "address")
//    var address: String?
//
//    @Field(key: "latitude")
//    var latitude: Double
//
//    @Field(key: "longitude")
//    var longitude: Double
//
//    @OptionalField(key: "websiteURL")
//    var websiteURL: String?
//
//    @OptionalField(key: "imageURL")
//    var imageURL: String?
//
//    @OptionalField(key: "description")
//    var description: String?
//
//    @Children(for: \.$shelter)
//    var pets: [Pet]
//
//    @Timestamp(key: "createdAt", on: .create)
//    var createdAt: Date?
//
//    @Timestamp(key: "updatedAt", on: .update)
//    var updatedAt: Date?
//
//    init() {}
//
//    init(id: UUID? = nil, name: String, contactEmail: String, latitude: Double, longitude: Double, phone: String? = nil, address: String? = nil, websiteURL: String? = nil, imageURL: String? = nil, description: String? = nil) {
//        self.id = id
//        self.name = name
//        self.contactEmail = contactEmail
//        self.latitude = latitude
//        self.longitude = longitude
//        self.phone = phone
//        self.address = address
//        self.websiteURL = websiteURL
//        self.imageURL = imageURL
//        self.description = description
//    }
//}

final class Shelter: Model, Content, @unchecked Sendable {
    static let schema = "shelters"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "contactEmail")
    var contactEmail: String

    @OptionalField(key: "phone")
    var phone: String?

    @OptionalField(key: "address")
    var address: String?

    @Field(key: "latitude")
    var latitude: Double

    @Field(key: "longitude")
    var longitude: Double

    @OptionalField(key: "websiteURL")
    var websiteURL: String?

    @OptionalField(key: "imageURL")
    var imageURL: String?

    @OptionalField(key: "description")
    var description: String?

    // ✅ Relación con User (Cada Shelter tiene un usuario propietario)
    @Parent(key: "ownerID")
    var owner: User

    // ✅ Relación con mascotas (Cada Shelter puede tener varias mascotas)
    @Children(for: \.$shelter)
    var pets: [Pet]

    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updatedAt", on: .update)
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, name: String, contactEmail: String, latitude: Double, longitude: Double, ownerID: UUID, phone: String? = nil, address: String? = nil, websiteURL: String? = nil, imageURL: String? = nil, description: String? = nil) {
        self.id = id
        self.name = name
        self.contactEmail = contactEmail
        self.latitude = latitude
        self.longitude = longitude
        self.owner.id = ownerID
        self.phone = phone
        self.address = address
        self.websiteURL = websiteURL
        self.imageURL = imageURL
        self.description = description
    }
}
