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

struct SellerLocation: Identifiable, Hashable {
    static func == (lhs: SellerLocation, rhs: SellerLocation) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    let id: String
    let sellerName: String
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    let typicalYield: String
    let certificationLevel: String
    let nextHarvestDate: Date
    let averageRating: Double
    let ratingCount: Int

    // Converts SellerLocation into a HarvestLot for the LiveBiddingView
    func toHarvestLot(currentBid: Double) -> HarvestLot {
        HarvestLot(
            id: id,
            sellerID: id,
            sellerInitial: sellerName,
            propertyName: "",
            locationName: locationName,
            coordinate: coordinate,
            quantity: Int(typicalYield) ?? 0,
            qualityGrade: "",
            currentBid: currentBid,
            endDate: nextHarvestDate
        )
    }
}
