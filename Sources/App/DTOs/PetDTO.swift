import Foundation
import Vapor

struct PetDTO: Content {
    let name: String
    let age: PetAge
    let description: String?
    let personality: String?
    let idealHome: String?
    let medicalCondition: String?
    let adoptionInfo: String?
    let breed: String
    let images: [String]?
    
    let size: PetSize
    let adoptionStatus: AdoptionStatus
    let species: Species
    let gender: PetGender
}
