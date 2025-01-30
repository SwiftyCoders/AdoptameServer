import Vapor
import Fluent

final class Favorite: Model, Content, @unchecked Sendable {
    static let schema = "favorites"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "userID")
    var user: User

    @Parent(key: "petID")
    var pet: Pet

    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?

    init() {}

    init(id: UUID? = nil, userID: UUID, petID: UUID) {
        self.id = id
        self.$user.id = userID
        self.$pet.id = petID
    }
}
