import Vapor
import Fluent

final class PasswordResetToken: Model, Content, @unchecked Sendable{
    static let schema = "password_reset_tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "token")
    var token: String

    @Parent(key: "user_id")
    var user: User

    @Field(key: "expires_at")
    var expiresAt: Date

    @Field(key: "used")
    var used: Bool

    init() {}

    init(token: String, userID: UUID, expiresAt: Date, used: Bool = false) {
        self.token = token
        self.$user.id = userID
        self.expiresAt = expiresAt
        self.used = used
    }
}

struct ForgotPasswordRequest: Content {
    let email: String
}
