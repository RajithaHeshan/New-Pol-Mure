// Location: New-Pol-Mure/Models/PriceTrend.swift

import Foundation

struct PriceTrend: Identifiable {
    let id: String      // "Mon", "Tue", … used as the chart x-axis label
    let day: String
    let price: Double
}
