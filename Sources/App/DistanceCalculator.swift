import Vapor
import JWT
import Fluent

struct DistanceCalculator {
    static let earthRadius = 6371000.0

    static func distance(from lat1: Double, lon1: Double, to lat2: Double, lon2: Double) -> Double {
        let latDiff = (lat2 - lat1) * .pi / 180
        let lonDiff = (lon2 - lon1) * .pi / 180
        let rLat1 = lat1 * .pi / 180
        let rLat2 = lat2 * .pi / 180

        let a = sin(latDiff / 2) * sin(latDiff / 2) +
                cos(rLat1) * cos(rLat2) *
                sin(lonDiff / 2) * sin(lonDiff / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadius * c
    }
}
