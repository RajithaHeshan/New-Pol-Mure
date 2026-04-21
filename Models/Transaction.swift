// Location: New-Pol-Mure/Models/Transaction.swift

import Foundation
import FirebaseFirestore

struct Transaction: Identifiable {
    let id: String              // Firestore document ID
    let buyerID: String
    let sellerID: String        // Present so both buyer and seller can filter their own records
    let description: String
    let amount: Double
    let isCredit: Bool          // true = refund/incoming, false = payment/outgoing
    let date: Date

    init?(id: String, data: [String: Any]) {
        guard
            let buyerID      = data["buyerID"]     as? String,
            let sellerID     = data["sellerID"]    as? String,
            let description  = data["description"] as? String,
            let amount       = data["amount"]      as? Double,
            let isCredit     = data["isCredit"]    as? Bool,
            let date         = (data["date"]       as? Timestamp)?.dateValue()
        else { return nil }

        self.id          = id
        self.buyerID     = buyerID
        self.sellerID    = sellerID
        self.description = description
        self.amount      = amount
        self.isCredit    = isCredit
        self.date        = date
    }
}
