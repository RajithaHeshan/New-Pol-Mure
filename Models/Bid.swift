// Location: New-Pol-Mure/Models/Bid.swift

import Foundation
import FirebaseFirestore

struct Bid: Identifiable {
    let id: String
    let harvestID: String   // Harvest document ID — used by LiveBiddingViewModel listener
    let sellerID: String    // Seller's user ID — used by SellerActivityDashboard
    let sellerName: String  // Seller's display name — shown in buyer's Activity tab
    let bidderID: String
    let bidderName: String
    let amount: Double
    let placedAt: Date
    let status: String      // "pending" | "accepted" | "declined"

    init?(id: String, data: [String: Any]) {
        guard
            let bidderID   = data["bidderID"]   as? String,
            let bidderName = data["bidderName"] as? String,
            let amount     = data["amount"]     as? Double,
            let placedAt   = (data["placedAt"]  as? Timestamp)?.dateValue()
        else { return nil }

        self.id         = id
        self.harvestID  = data["harvestID"]  as? String ?? ""
        self.sellerID   = data["sellerID"]   as? String ?? ""
        self.sellerName = data["sellerName"] as? String ?? ""
        self.bidderID   = bidderID
        self.bidderName = bidderName
        self.amount     = amount
        self.placedAt   = placedAt
        self.status     = data["status"] as? String ?? "pending"
    }
}
