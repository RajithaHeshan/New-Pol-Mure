
import Foundation
import CoreLocation

struct RegisteredBuyer: Identifiable {
    let id = UUID()
    let name: String
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    let typicalVolume: String
    let volumeCapacity: Int
    let rating: Double
    let isUrgent: Bool
}
