import Vapor
import Fluent

final class ShelterCode: Model, Content, @unchecked Sendable {
    static let schema = "shelter_codes"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "code")
    var code: String

    @Field(key: "shelterName")
    var shelterName: String

    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?

    init() {}

    init(id: UUID? = nil, code: String, shelterName: String) {
        self.id = id
        self.code = code
        self.shelterName = shelterName
    }
}
