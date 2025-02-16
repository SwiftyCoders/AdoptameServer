import Vapor
import Fluent

struct ShelterDTO: Content, @unchecked Sendable {
    var name: String
    var contactEmail: String
    var phone: String?
    var address: String?
    var latitude: Double
    var longitude: Double
    var websiteURL: String?
    var image: String?
    var description: String?
}
