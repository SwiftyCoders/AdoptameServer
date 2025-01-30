import Vapor
import Fluent

final class Pet: Model, Content, @unchecked Sendable {
    static let schema = "pets"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "shelterID")
    var shelter: Shelter

    @Field(key: "name")
    var name: String

    @OptionalField(key: "age")
    var age: Int?

    @Field(key: "description")
    var description: String

    @Enum(key: "species")
    var species: Species

    @OptionalField(key: "breed")
    var breed: String?

    @OptionalField(key: "weight")
    var weight: Double?

    @Enum(key: "size")
    var size: PetSize

    @Enum(key: "adoptionStatus")
    var adoptionStatus: AdoptionStatus

    @OptionalField(key: "imageURLs")
    var imageURLs: [String]?

    @Field(key: "latitude")
    var latitude: Double

    @Field(key: "longitude")
    var longitude: Double

    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updatedAt", on: .update)
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, shelterID: UUID, name: String, age: Int? = nil, description: String, species: Species, breed: String? = nil, weight: Double? = nil, size: PetSize, adoptionStatus: AdoptionStatus, imageURLs: [String]? = nil, latitude: Double, longitude: Double) {
        self.id = id
        self.$shelter.id = shelterID
        self.name = name
        self.age = age
        self.description = description
        self.species = species
        self.breed = breed
        self.weight = weight
        self.size = size
        self.adoptionStatus = adoptionStatus
        self.imageURLs = imageURLs
        self.latitude = latitude
        self.longitude = longitude
    }
}

enum Species: String, Codable {
    case dog, cat, other
}

enum PetSize: String, Codable {
    case small, medium, large
}

enum AdoptionStatus: String, Codable {
    case available, inProgress, adopted
}
