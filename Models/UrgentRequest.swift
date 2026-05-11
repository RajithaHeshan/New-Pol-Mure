// Location: New-Pol-Mure/Models/UrgentRequest.swift

import Foundation
import FirebaseFirestore

struct UrgentRequest: Identifiable {
    let id: String              // Firestore document ID
    let buyerID: String         // The buyer who posted this request
    let buyerName: String
    let quantity: Int
    let grade: String
    let location: String
    let deadline: Date

    init?(id: String, data: [String: Any]) {
        guard
            let buyerID   = data["buyerID"]   as? String,
            let buyerName = data["buyerName"] as? String,
            let quantity  = data["quantity"]  as? Int,
            let grade     = data["grade"]     as? String,
            let location  = data["location"]  as? String,
            let deadline  = (data["deadline"] as? Timestamp)?.dateValue()
        else { return nil }

        self.id        = id
        self.buyerID   = buyerID
        self.buyerName = buyerName
        self.quantity  = quantity
        self.grade     = grade
        self.location  = location
        self.deadline  = deadline
    }
}
