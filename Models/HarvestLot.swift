//
//import Foundation
//import CoreLocation
//
//struct HarvestLot: Identifiable {
//    let id = UUID()
//    let sellerInitial: String
//    let locationName: String
//    let coordinate: CLLocationCoordinate2D
//    let quantity: Int
//    let currentBid: Double
//    let endDate: Date
//}






import Foundation
import CoreLocation

struct HarvestLot: Identifiable {
    let id: String          // Firestore seller document ID
    let sellerInitial: String
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    let quantity: Int
    let currentBid: Double
    let endDate: Date
}
