// Location: New-Pol-Mure/Models/Contract.swift

import Foundation
import FirebaseFirestore

struct Contract: Identifiable {
    let id: String              // Firestore document ID
    let contractRef: String     // Human-readable reference e.g. "#8842"
    let buyerID: String
    let sellerID: String
    let sellerName: String
    let status: String          // "escrow" | "inspection" | "completed" | "rejected"
    let amount: Double
    let createdAt: Date

    init?(id: String, data: [String: Any]) {
        guard
            let contractRef = data["contractRef"] as? String,
            let buyerID     = data["buyerID"]     as? String,
            let sellerID    = data["sellerID"]    as? String,
            let sellerName  = data["sellerName"]  as? String,
            let status      = data["status"]      as? String,
            let amount      = data["amount"]      as? Double,
            let createdAt   = (data["createdAt"]  as? Timestamp)?.dateValue()
        else { return nil }

        self.id          = id
        self.contractRef = contractRef
        self.buyerID     = buyerID
        self.sellerID    = sellerID
        self.sellerName  = sellerName
        self.status      = status
        self.amount      = amount
        self.createdAt   = createdAt
    }
}
