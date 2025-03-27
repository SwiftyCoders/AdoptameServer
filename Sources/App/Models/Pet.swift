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
    
    @OptionalEnum(key: "age")
    var age: PetAge?

    @OptionalField(key: "description")
    var description: String?
    
    @OptionalField(key: "personality")
    var personality: String?
    
    @OptionalField(key: "idealHome")
    var idealHome: String?
    
    @OptionalField(key: "medicalCondition")
    var medicalCondition: String?
    
    @OptionalField(key: "adoptionInfo")
    var adoptionInfo: String?

    @Enum(key: "species")
    var species: Species

    @OptionalField(key: "breed")
    var breed: String?

    @Enum(key: "size")
    var size: PetSize
    
    @Enum(key: "gender")
    var gender: PetGender

    @Enum(key: "adoptionStatus")
    var adoptionStatus: AdoptionStatus

    @OptionalField(key: "imageURLs")
    var imageURLs: [String]?

    @Field(key: "latitude")
    var latitude: Double

    @Field(key: "longitude")
    var longitude: Double
    
    @Field(key: "location")
    var location: String

    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updatedAt", on: .update)
    var updatedAt: Date?

    init() {}
    
    init(id: UUID? = nil, shelterID: UUID, name: String, age: PetAge? = nil, description: String? = nil, personality: String? = nil, idealHome: String? = nil, medicalCondition: String? = nil, adoptionInfo: String? = nil, species: Species, breed: String? = nil, size: PetSize, gender: PetGender, adoptionStatus: AdoptionStatus, imageURLs: [String]? = nil, latitude: Double, longitude: Double, location: String, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.$shelter.id = shelterID
        self.name = name
        self.age = age
        self.description = description
        self.personality = personality
        self.idealHome = idealHome
        self.medicalCondition = medicalCondition
        self.adoptionInfo = adoptionInfo
        self.species = species
        self.breed = breed
        self.size = size
        self.gender = gender
        self.adoptionStatus = adoptionStatus
        self.imageURLs = imageURLs
        self.latitude = latitude
        self.longitude = longitude
        self.location = location
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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

enum PetAge: String, Codable, CaseIterable {
    case baby
    case young
    case adult
    case senior
}

enum PetGender: String, Codable, CaseIterable {
    case male
    case female
}







//    init(id: UUID? = nil, shelterID: UUID, name: String, age: PetAge? = nil, description: String, species: Species, breed: String? = nil, size: PetSize, adoptionStatus: AdoptionStatus, imageURLs: [String]? = nil, latitude: Double, longitude: Double) {
//        self.id = id
//        self.$shelter.id = shelterID
//        self.name = name
//        self.age = age
//        self.description = description
//        self.species = species
//        self.breed = breed
//        self.size = size
//        self.adoptionStatus = adoptionStatus
//        self.imageURLs = imageURLs
//        self.latitude = latitude
//        self.longitude = longitude
//    }
