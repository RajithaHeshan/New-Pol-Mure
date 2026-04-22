// Location: New-Pol-Mure/Models/Contract.swift

import Foundation
import FirebaseFirestore

struct Contract: Identifiable, Hashable {
    let id: String              // Firestore document ID
    let contractRef: String     // Human-readable reference e.g. "#8842"
    let buyerID: String
    let buyerName: String
    let sellerID: String
    let sellerName: String
    let status: String          // "escrow" | "inspection" | "payment" | "completed" | "rejected"
    let amount: Double
    let createdAt: Date
    let inspectionDate: Date?   // Written when buyer reveals exact location

    init?(id: String, data: [String: Any]) {
        guard
            let contractRef = data["contractRef"] as? String,
            let buyerID     = data["buyerID"]     as? String,
            let buyerName   = data["buyerName"]   as? String,
            let sellerID    = data["sellerID"]    as? String,
            let sellerName  = data["sellerName"]  as? String,
            let status      = data["status"]      as? String,
            let amount      = data["amount"]      as? Double,
            let createdAt   = (data["createdAt"]  as? Timestamp)?.dateValue()
        else { return nil }

        self.id             = id
        self.contractRef    = contractRef
        self.buyerID        = buyerID
        self.buyerName      = buyerName
        self.sellerID       = sellerID
        self.sellerName     = sellerName
        self.status         = status
        self.amount         = amount
        self.createdAt      = createdAt
        self.inspectionDate = (data["inspectionDate"] as? Timestamp)?.dateValue()
    }
}
