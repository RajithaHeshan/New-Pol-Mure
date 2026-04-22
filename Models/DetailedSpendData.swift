// Location: New-Pol-Mure/Models/DetailedSpendData.swift

import Foundation

struct DetailedSpendData: Identifiable {
    let id: String          // Stable key: "\(period)-\(source)"
    let period: String
    let amount: Double
    let source: String      // "Bids Won" | "Accepted Offers"
}
