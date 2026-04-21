
import Foundation
import CoreLocation

struct RegisteredBuyer: Identifiable {
    let id: String
    let name: String
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    let typicalVolume: String
    let rating: Double
    let isUrgent: Bool
}
