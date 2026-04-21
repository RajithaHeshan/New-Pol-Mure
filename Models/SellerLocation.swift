//import Foundation
//import CoreLocation
//
//struct SellerLocation: Identifiable {
//    let id: String
//    let sellerName: String
//    let locationName: String
//    let coordinate: CLLocationCoordinate2D
//    let typicalYield: String
//    let certificationLevel: String
//    let nextHarvestDate: Date
//}




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

    // Converts SellerLocation into a HarvestLot for the LiveBiddingView
    func toHarvestLot(currentBid: Double) -> HarvestLot {
        HarvestLot(
            id: id,
            sellerInitial: sellerName,
            locationName: locationName,
            coordinate: coordinate,
            quantity: Int(typicalYield) ?? 0,
            currentBid: currentBid,
            endDate: nextHarvestDate
        )
    }
}
