// Location: New-Pol-Mure/Models/Offer.swift

import Foundation
import FirebaseFirestore

struct Offer: Identifiable {
    let id: String
    let buyerID: String
    let buyerName: String
    let sellerID: String
    let sellerName: String
    let amount: Double
    let placedAt: Date
    let status: String          // "pending" | "accepted" | "declined"
    let isUrgentPitch: Bool

    init?(id: String, data: [String: Any]) {
        guard
            let buyerID    = data["buyerID"]    as? String,
            let sellerID   = data["sellerID"]   as? String,
            let sellerName = data["sellerName"] as? String,
            let amount     = data["amount"]     as? Double,
            let placedAt   = (data["placedAt"]  as? Timestamp)?.dateValue()
        else { return nil }

        self.id             = id
        self.buyerID        = buyerID
        self.buyerName      = data["buyerName"] as? String ?? ""
        self.sellerID       = sellerID
        self.sellerName     = sellerName
        self.amount         = amount
        self.placedAt       = placedAt
        self.status         = data["status"]        as? String ?? "pending"
        self.isUrgentPitch  = data["isUrgentPitch"] as? Bool   ?? false
    }
}
