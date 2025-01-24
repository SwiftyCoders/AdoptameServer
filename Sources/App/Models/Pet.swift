import Fluent
import struct Foundation.UUID

final class Pet: Model, @unchecked Sendable {
    static let schema = "pets"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    init(){}
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
