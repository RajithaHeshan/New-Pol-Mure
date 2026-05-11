
import Foundation
import CoreLocation

struct RegisteredBuyer: Identifiable {
    let id: String
    let name: String
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    let typicalVolume: String
    let businessType: String
    let rating: Double
    let ratingCount: Int
    let isUrgent: Bool
}
