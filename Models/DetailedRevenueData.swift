// Location: New-Pol-Mure/Models/DetailedRevenueData.swift

import Foundation

struct DetailedRevenueData: Identifiable {
    let id: String          // Stable key: "\(period)-\(source)"
    let period: String
    let amount: Double
    let source: String      // "Auction Sales" | "Accepted Pitches"
}
