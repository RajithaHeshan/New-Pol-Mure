// Location: New-Pol-Mure/Features/MarketPlace/ViewModels/MarketAnalyticsViewModel.swift

import SwiftUI
import FirebaseFirestore

private final class AnalyticsListenerBox {
    var listener: ListenerRegistration?
    init() {}
    deinit { listener?.remove() }
}

@Observable
@MainActor
class MarketAnalyticsViewModel {

    // MARK: - Chart Data
    var priceHistory: [PriceTrend] = []

    // MARK: - Summary Stats (drive the header card)
    var currentMarketAverage: Double = 0
    var weeklyChangePercent: Double  = 0  // positive = up, negative = down

    // MARK: - Market Insight
    var marketInsight: String = "Analysing market trends…"

    // MARK: - Loading State
    var isLoading = false

    private let bidsListenerBox = AnalyticsListenerBox()

    init() {
        attachBidsListener()
    }

    // MARK: - Live Listener: derive 7-day trend from the bids collection
    private func attachBidsListener() {
        isLoading = true

        // Look back 14 days so we can compute a week-over-week change
        let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()

        bidsListenerBox.listener = Firestore.firestore()
            .collection("bids")
            .whereField("placedAt", isGreaterThan: Timestamp(date: fourteenDaysAgo))
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Analytics bids listener error: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }

                let allBids = snapshot?.documents.compactMap {
                    Bid(id: $0.documentID, data: $0.data())
                } ?? []

                self.computeTrend(from: allBids)
                self.isLoading = false
            }
    }

    // MARK: - Compute 7-Day Trend + Stats from raw bids
    private func computeTrend(from bids: [Bid]) {
        let calendar = Calendar.current
        let today    = calendar.startOfDay(for: Date())

        // Build day-label → average bid price map for the last 7 days
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"     // "Mon", "Tue", …

        var thisWeekTotals: [Int: (sum: Double, count: Int)] = [:]  // dayOffset (0=today … 6=6 days ago)
        var prevWeekTotals: [Int: (sum: Double, count: Int)] = [:]  // dayOffset 7–13

        for bid in bids {
            let bidDay  = calendar.startOfDay(for: bid.placedAt)
            let offset  = calendar.dateComponents([.day], from: bidDay, to: today).day ?? 999

            if offset >= 0 && offset < 7 {
                let existing = thisWeekTotals[offset] ?? (0, 0)
                thisWeekTotals[offset] = (existing.sum + bid.amount, existing.count + 1)
            } else if offset >= 7 && offset < 14 {
                let key      = offset - 7
                let existing = prevWeekTotals[key] ?? (0, 0)
                prevWeekTotals[key] = (existing.sum + bid.amount, existing.count + 1)
            }
        }

        // Build the ordered 7-day array (oldest → newest, so chart reads left to right)
        var trends: [PriceTrend] = []
        for offset in stride(from: 6, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let label = dayFormatter.string(from: date)
            let avg: Double
            if let entry = thisWeekTotals[offset], entry.count > 0 {
                avg = entry.sum / Double(entry.count)
            } else {
                // No bids that day — carry forward the previous point or use 0
                avg = trends.last?.price ?? 0
            }
            trends.append(PriceTrend(id: label, day: label, price: avg))
        }

        priceHistory = trends

        // Current market average = average of the most recent day that has data
        if let latest = trends.last(where: { $0.price > 0 }) {
            currentMarketAverage = latest.price
        }

        // Week-over-week change
        let thisWeekAvg = thisWeekTotals.values.reduce((0.0, 0)) { ($0.0 + $1.sum, $0.1 + $1.count) }
        let prevWeekAvg = prevWeekTotals.values.reduce((0.0, 0)) { ($0.0 + $1.sum, $0.1 + $1.count) }

        let thisAvg = thisWeekAvg.1 > 0 ? thisWeekAvg.0 / Double(thisWeekAvg.1) : 0
        let prevAvg = prevWeekAvg.1 > 0 ? prevWeekAvg.0 / Double(prevWeekAvg.1) : 0

        if prevAvg > 0 {
            weeklyChangePercent = ((thisAvg - prevAvg) / prevAvg) * 100
        } else {
            weeklyChangePercent = 0
        }

        updateInsight()
    }

    // MARK: - Dynamic Insight Text
    private func updateInsight() {
        if priceHistory.allSatisfy({ $0.price == 0 }) {
            marketInsight = "Not enough market data yet. Check back after the first bids are placed."
            return
        }

        switch weeklyChangePercent {
        case let x where x > 10:
            marketInsight = "Prices are rising sharply this week. Sellers should list now to capture peak demand, while buyers may want to act quickly before prices climb further."
        case let x where x > 0:
            marketInsight = "Prices are trending upwards this week. Competition is moderate — a well-timed bid or pitch can secure a favourable deal."
        case let x where x < -10:
            marketInsight = "Prices have dropped significantly this week. Buyers have stronger negotiating power right now."
        case let x where x < 0:
            marketInsight = "Prices are slightly softer this week. A good opportunity for buyers to secure stock at competitive rates."
        default:
            marketInsight = "Prices are stable this week. Market conditions are balanced between supply and demand."
        }
    }

    // MARK: - Formatted Helpers (consumed by the View)
    var chartYDomain: ClosedRange<Double> {
        let prices = priceHistory.map { $0.price }.filter { $0 > 0 }
        guard let minP = prices.min(), let maxP = prices.max(), minP < maxP else {
            return 90...130
        }
        let padding = (maxP - minP) * 0.2
        return (minP - padding)...(maxP + padding)
    }

    var weeklyChangeLabel: String {
        let sign   = weeklyChangePercent >= 0 ? "+" : ""
        let color  = weeklyChangePercent >= 0 ? "▲" : "▼"
        return "\(color) \(sign)\(String(format: "%.1f", weeklyChangePercent))% from last week"
    }

    var weeklyChangeIsPositive: Bool {
        weeklyChangePercent >= 0
    }
}
