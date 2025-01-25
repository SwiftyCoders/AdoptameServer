import Fluent
import Vapor

final class Pet: Model, Content, @unchecked Sendable {
    static let schema = "pets"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: .name)
    var name: String
    
    @Field(key: .accessKey)
    var accessKey: UUID?
    
    @Field(key: .age)
    var age: String
    
    @Field(key: .breed)
    var breed: String?
    
    @Field(key: .summary)
    var summary: String?
    
    @Field(key: .type)
    var type: String?
    
    @Field(key: .size)
    var size: String?
    
    @Field(key: .status)
    var status: String?
    
    @Field(key: .color)
    var color: String?
    
    init() {}
    
    init(id: UUID? = nil, name: String, accessKey: UUID? = nil, age: String, breed: String? = nil, summary: String? = nil, type: String? = nil, size: String? = nil, status: String? = nil, color: String? = nil) {
        self.id = id
        self.name = name
        self.accessKey = accessKey
        self.age = age
        self.breed = breed
        self.summary = summary
        self.type = type
        self.size = size
        self.status = status
        self.color = color
    }
}
