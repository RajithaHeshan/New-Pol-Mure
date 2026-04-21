// Location: New-Pol-Mure/Models/Bid.swift

import Foundation
import FirebaseFirestore

struct Bid: Identifiable {
    let id: String              // Firestore document ID
    let sellerID: String        // Seller's user document ID (links to HarvestLot.id)
    let bidderID: String        // Buyer's user document ID
    let bidderName: String
    let amount: Double
    let placedAt: Date

    init?(id: String, data: [String: Any]) {
        guard
            let sellerID = data["sellerID"] as? String,
            let bidderID = data["bidderID"] as? String,
            let bidderName = data["bidderName"] as? String,
            let amount = data["amount"] as? Double,
            let placedAt = (data["placedAt"] as? Timestamp)?.dateValue()
        else { return nil }

        self.id = id
        self.sellerID = sellerID
        self.bidderID = bidderID
        self.bidderName = bidderName
        self.amount = amount
        self.placedAt = placedAt
    }
}


