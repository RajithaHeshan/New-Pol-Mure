import Foundation
import CoreLocation

struct SellerLocation: Identifiable {
    let id: String
    let sellerName: String
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    let typicalYield: String
    let certificationLevel: String
    let nextHarvestDate: Date
}

