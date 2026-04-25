import Foundation
import FirebaseFirestore

struct Contract: Identifiable, Hashable {
    let id: String
    let contractRef: String
    let buyerID: String
    let buyerName: String
    let sellerID: String
    let sellerName: String
    let status: String
    let amount: Double
    let quantity: Int
    let locationName: String
    let createdAt: Date
    let inspectionDate: Date?
    let harvestLatitude: Double?
    let harvestLongitude: Double?
    let source: String  // "bid" or "offer"

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

        self.id               = id
        self.contractRef      = contractRef
        self.buyerID          = buyerID
        self.buyerName        = buyerName
        self.sellerID         = sellerID
        self.sellerName       = sellerName
        self.status           = status
        self.amount           = amount
        self.quantity         = data["quantity"]      as? Int    ?? 0
        self.locationName     = data["locationName"]  as? String ?? ""
        self.createdAt        = createdAt
        self.inspectionDate   = (data["inspectionDate"] as? Timestamp)?.dateValue()
        self.harvestLatitude  = data["harvestLatitude"]  as? Double
        self.harvestLongitude = data["harvestLongitude"] as? Double
        self.source           = data["source"]           as? String ?? "bid"
    }
}
