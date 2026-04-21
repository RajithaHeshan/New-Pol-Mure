import Foundation
import FirebaseFirestore

struct Offer: Identifiable {
    let id: String              // Firestore document ID
    let buyerID: String         // Buyer's user document ID (the target buyer)
    let sellerID: String
    let sellerName: String
    let amount: Double
    let placedAt: Date

    init?(id: String, data: [String: Any]) {
        guard
            let buyerID   = data["buyerID"]    as? String,
            let sellerID  = data["sellerID"]   as? String,
            let sellerName = data["sellerName"] as? String,
            let amount    = data["amount"]     as? Double,
            let placedAt  = (data["placedAt"]  as? Timestamp)?.dateValue()
        else { return nil }

        self.id         = id
        self.buyerID    = buyerID
        self.sellerID   = sellerID
        self.sellerName = sellerName
        self.amount     = amount
        self.placedAt   = placedAt
    }
}



