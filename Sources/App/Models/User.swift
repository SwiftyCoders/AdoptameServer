import Vapor
import Fluent

final class User: Model, Content, Authenticatable, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "email")
    var email: String

    @Enum(key: "role")
    var role: UserRole

    @OptionalParent(key: "shelterID")
    var shelter: Shelter?

    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updatedAt", on: .update)
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, name: String, email: String, role: UserRole, shelterID: UUID? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.$shelter.id = shelterID
    }
}

enum UserRole: String, Codable {
    case adopter
    case shelter
}
