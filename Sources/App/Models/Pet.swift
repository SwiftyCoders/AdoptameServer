import Fluent
import Vapor

enum PetType: String, Codable {
    case dog
    case cat
    case rabbit
    case bird
    case reptile
    case other
}

enum PetSize: String, Codable {
    case small
    case medium
    case large
}

final class Pet: Model, Content, @unchecked Sendable {
    static let schema = "pets"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "age")
    var age: Int
    
    @Enum(key: "pet_type")
    var type: PetType
    
    @Enum(key: "pet_size")
    var size: PetSize
    
    @Field(key: "breed")
    var breed: String?
    
    @Field(key: "description")
    var description: String
    
    @Field(key: "photo_url")
    var photoUrl: String
    
    @Field(key: "status")
    var status: String
    
    @Parent(key: "protector_id")
    var protectora: Protector
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() {}
    
    init(
        id: UUID? = nil,
        name: String,
        age: Int,
        type: PetType,
        size: PetSize,
        breed: String? = nil,
        description: String,
        photoUrl: String,
        status: String,
        protectoraID: UUID
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.type = type
        self.size = size
        self.breed = breed
        self.description = description
        self.photoUrl = photoUrl
        self.status = status
        self.$protectora.id = protectoraID
    }
}
