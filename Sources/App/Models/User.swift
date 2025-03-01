import Vapor
import Fluent

final class User: Model, Content, Authenticatable, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "appleUserID")
    var appleUserID: String
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String?
    
    //NEW
    @Field(key: "password")
    var password: String
    
    @Enum(key: "role")
    var role: UserRole
    
    @OptionalField(key: "shelterID")
    var shelterID: UUID?
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updatedAt", on: .update)
    var updatedAt: Date?
    
    //MARK: NEW
    @Children(for: \.$user) var token: [UserToken]
    //MARK: NEW

    init() {}
    
    init(id: UUID? = nil, appleUserID: String, name: String, email: String, password: String, role: UserRole, shelterID: UUID? = nil) {
        self.id = id
        self.appleUserID = appleUserID
        self.name = name
        self.email = email
        self.password = password
        self.role = role
        self.shelterID = shelterID
    }
    
    //MARK: NEW
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$password
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
    
    func generateToken() throws -> UserToken {
        try UserToken(
            value: [UInt8].random(count: 24).base64,
            userID: self.requireID()
        )
    }
    
    struct Create: Content, Validatable {
        var name: String
        var email: String
        var password: String
        
        static func validations(_ validations: inout Validations) {
            validations.add("name", as: String.self, is: .alphanumeric)
            validations.add("email", as: String.self, is: .email)
            validations.add("password", as: String.self, is: .count(4...))
        }
    }
    //MARK: NEW
}

//MARK: NEW
final class UserToken: Model, Content, ModelTokenAuthenticatable, @unchecked Sendable {
    static let schema = "user_tokens"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "value") var value: String
    @Parent(key: "user_id") var user: User
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
    
    static let valueKey = \UserToken.$value
    static let userKey = \UserToken.$user
    
    var isValid: Bool {
        guard let createdAt else {
            return false
        }
        
        let timeInterval = Date().timeIntervalSince(createdAt)
        return timeInterval <= (48 * 60 * 60)
    }
}
//MARK: NEW


enum UserRole: String, Codable {
    case adopter
    case shelter
}
