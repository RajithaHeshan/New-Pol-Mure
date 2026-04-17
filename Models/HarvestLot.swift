
import Foundation
import CoreLocation

struct HarvestLot: Identifiable {
    let id = UUID()
    let sellerInitial: String
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    let quantity: Int
    let currentBid: Double
    let endDate: Date
}

