import Foundation

struct PriceTrend: Identifiable {
    let id: String      // "Thu 24 Apr" — unique per day, used as chart x-axis label
    let day: String     // "Thu" — short day name
    let date: Date      // actual calendar date for this data point
    let price: Double
}
