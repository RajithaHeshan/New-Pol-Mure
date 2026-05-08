

import Foundation
import FirebaseFirestore

struct Bid: Identifiable {
    let id: String
    let harvestID: String   
    let sellerID: String    
    let sellerName: String 
    let bidderID: String
    let bidderName: String
    let amount: Double
    let placedAt: Date
    let status: String      // "pending" | "accepted" | "declined"

    init?(id: String, data: [String: Any]) {  //requiremnt missing data incompleted skiped 
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
