import Foundation
import CoreLocation

struct HarvestLot: Identifiable {
    let id: String          // Firestore harvest document ID
    let sellerID: String    // The seller's user ID (for bid routing)
    let sellerInitial: String
    let propertyName: String
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    let quantity: Int
    let qualityGrade: String
    let currentBid: Double
    let endDate: Date
}
