import Foundation
import FirebaseFirestore

struct Transaction: Identifiable {
    let id: String
    let contractRef: String
    let buyerID: String
    let buyerName: String
    let sellerID: String
    let sellerName: String
    let quantity: Int
    let pricePerNut: Double
    let amount: Double
    let transactionFee: Double
    let locationName: String
    let harvestName: String
    let isCredit: Bool
    let completedAt: Date
    let source: String  // "bid" or "offer" — set at transaction creation time
    let isUrgent: Bool  // true when transaction originated from an urgent post pitch

    var netAmount: Double { isCredit ? amount - transactionFee : amount - transactionFee }

    init?(id: String, data: [String: Any]) {
        guard
            let buyerID    = data["buyerID"]    as? String,
            let sellerID   = data["sellerID"]   as? String,
            let amount     = data["amount"]     as? Double,
            let isCredit   = data["isCredit"]   as? Bool,
            let completedAt = (data["completedAt"] as? Timestamp)?.dateValue()
        else { return nil }

        self.id             = id
        self.contractRef    = data["contractRef"]   as? String ?? ""
        self.buyerID        = buyerID
        self.buyerName      = data["buyerName"]     as? String ?? ""
        self.sellerID       = sellerID
        self.sellerName     = data["sellerName"]    as? String ?? ""
        self.quantity       = data["quantity"]      as? Int    ?? 0
        self.pricePerNut    = data["pricePerNut"]   as? Double ?? 0
        self.amount         = amount
        self.transactionFee = data["transactionFee"] as? Double ?? 0
        self.locationName   = data["locationName"]  as? String ?? ""
        self.harvestName    = data["harvestName"]   as? String ?? ""
        self.isCredit       = isCredit
        self.completedAt    = completedAt
        self.source         = data["source"]        as? String ?? "bid"
        self.isUrgent       = data["isUrgent"]      as? Bool   ?? false
    }
}
