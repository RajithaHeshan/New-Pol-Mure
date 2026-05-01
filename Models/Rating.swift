import Foundation
import FirebaseFirestore

struct Rating: Identifiable {
    let id: String
    let contractID: String
    let reviewerID: String
    let reviewerName: String
    let revieweeID: String
    let stars: Int           
    let comment: String
    let createdAt: Date

    init?(id: String, data: [String: Any]) {
        guard
            let contractID   = data["contractID"]   as? String,
            let reviewerID   = data["reviewerID"]   as? String,
            let revieweeID   = data["revieweeID"]   as? String,
            let stars        = data["stars"]         as? Int,
            let createdAt    = (data["createdAt"]    as? Timestamp)?.dateValue()
        else { return nil }

        self.id           = id
        self.contractID   = contractID
        self.reviewerID   = reviewerID
        self.reviewerName = data["reviewerName"] as? String ?? ""
        self.revieweeID   = revieweeID
        self.stars        = stars
        self.comment      = data["comment"]      as? String ?? ""
        self.createdAt    = createdAt
    }
}
