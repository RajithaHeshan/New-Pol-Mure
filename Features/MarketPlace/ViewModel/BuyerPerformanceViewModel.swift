import SwiftUI
import FirebaseFirestore

private final class BuyerPerformanceListenerBox {
    var listener: ListenerRegistration?
    init() {}
    deinit { listener?.remove() }
}

private let buyerPerfDayFormatter: DateFormatter = {
    let f = DateFormatter(); f.dateFormat = "EEE"; return f
}()

private let buyerPerfMonthFormatter: DateFormatter = {
    let f = DateFormatter(); f.dateFormat = "MMM"; return f
}()

@Observable
@MainActor
class BuyerPerformanceViewModel {

    // MARK: - Timeframe Picker
    var selectedTimeframe = "Month"
    let timeframes = ["Week", "Month", "Year"]

    // MARK: - KPI Values (all timeframe-filtered)
    var totalVolumeNuts: Int = 0
    var winRate: Int         = 0

    // MARK: - Chart Data
    var detailedSpendData: [DetailedSpendData] = []

    // MARK: - Dynamic KPI (computed from filtered chart data)
    var totalSpend: Double {
        detailedSpendData.reduce(0) { $0 + $1.amount }
    }

    var hasNoSpendData: Bool {
        detailedSpendData.allSatisfy { $0.amount == 0 }
    }

    // MARK: - Dynamic Insights
    var insightSourcingDesc: String      = "Analysing your acquisition cost…"
    var insightBidSuccessDesc: String    = "Analysing your bid win rate…"
    var insightOfferRelianceDesc: String = "Analysing your spend mix…"

    // MARK: - Loading State
    var isLoading = false

    private let currentBuyerID: String

    // Raw fetched data — kept all-time; re-filtered on timeframe change
    private var allTransactions: [Transaction] = []
    private var allBids:         [Bid]         = []

    private let transactionsListenerBox = BuyerPerformanceListenerBox()
    private let bidsListenerBox         = BuyerPerformanceListenerBox()

    init() {
        self.currentBuyerID = AuthManager.shared.currentUserID
        if currentBuyerID.isEmpty {
            // Face ID login may not have saved session yet — retry once after 1s
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self.attachTransactionsListener()
                self.attachBidsListener()
            }
        } else {
            attachTransactionsListener()
            attachBidsListener()
        }
    }

    func onTimeframeChanged() {
        recompute()
    }

    // MARK: - Rolling window start for the selected timeframe
    private func windowStart(calendar: Calendar, now: Date) -> Date {
        switch selectedTimeframe {
        case "Week":  return calendar.date(byAdding: .day,   value: -6,  to: calendar.startOfDay(for: now)) ?? now
        case "Year":  return calendar.date(byAdding: .month, value: -11, to: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!) ?? now
        default:      return calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        }
    }

    // MARK: - Listeners

    private func attachTransactionsListener() {
        guard !currentBuyerID.isEmpty else { return }
        isLoading = true

        transactionsListenerBox.listener = Firestore.firestore()
            .collection("transactions")
            .whereField("buyerID", isEqualTo: currentBuyerID)
            .whereField("isCredit", isEqualTo: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("Buyer performance transactions error: \(error.localizedDescription)")
                    self.isLoading = false; return
                }
                self.allTransactions = snapshot?.documents.compactMap {
                    Transaction(id: $0.documentID, data: $0.data())
                } ?? []
                self.recompute()
                self.isLoading = false
            }
    }

    private func attachBidsListener() {
        guard !currentBuyerID.isEmpty else { return }

        bidsListenerBox.listener = Firestore.firestore()
            .collection("bids")
            .whereField("bidderID", isEqualTo: currentBuyerID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("Buyer performance bids error: \(error.localizedDescription)")
                    return
                }
                self.allBids = snapshot?.documents.compactMap {
                    Bid(id: $0.documentID, data: $0.data())
                } ?? []
                self.recompute()
            }
    }

    // MARK: - Central recompute
    private func recompute() {
        let calendar = Calendar.current
        let now      = Date()
        let start    = windowStart(calendar: calendar, now: now)

        // Filter transactions by completedAt (when money actually moved)
        let windowTransactions = allTransactions.filter { $0.completedAt >= start }
        // Filter contracts by completedAt via matching transactions — use transaction quantity for accuracy
        let windowBids         = allBids.filter { $0.placedAt >= start }

        // Nuts acquired = sum of quantities from window transactions (completedAt is accurate)
        totalVolumeNuts = windowTransactions.reduce(0) { $0 + $1.quantity }

        // Win rate: compare buyer's top bid per harvest against ALL bids in the same window only
        var highestBidPerHarvest: [String: Double] = [:]
        for bid in windowBids {
            if (highestBidPerHarvest[bid.harvestID] ?? 0) < bid.amount {
                highestBidPerHarvest[bid.harvestID] = bid.amount
            }
        }
        let windowHarvestIDs = Set(windowBids.filter { $0.bidderID == currentBuyerID }.map { $0.harvestID })
        let myTopBidPerHarvest: [String: Double] = windowBids
            .filter { $0.bidderID == currentBuyerID }
            .reduce(into: [:]) { map, bid in
                if (map[bid.harvestID] ?? 0) < bid.amount {
                    map[bid.harvestID] = bid.amount
                }
            }
        let totalLots = windowHarvestIDs.count
        let wonLots   = myTopBidPerHarvest.filter { harvestID, myTop in
            highestBidPerHarvest[harvestID] == myTop
        }.count
        winRate = totalLots > 0 ? Int((Double(wonLots) / Double(totalLots)) * 100) : 0

        recomputeChartData(transactions: windowTransactions, calendar: calendar, now: now)
        updateInsights(windowTransactions: windowTransactions)
    }

    // MARK: - Chart bucket grouping
    private func recomputeChartData(transactions: [Transaction], calendar: Calendar, now: Date) {
        var bidsBuckets:   [String: Double] = [:]
        var offersBuckets: [String: Double] = [:]

        for tx in transactions {
            let key = periodLabel(for: tx.completedAt, calendar: calendar, now: now)
            if tx.source == "offer" {
                offersBuckets[key, default: 0] += tx.amount
            } else {
                bidsBuckets[key, default: 0] += tx.amount
            }
        }

        let periods = orderedPeriodLabels(calendar: calendar, now: now)
        var result: [DetailedSpendData] = []
        for period in periods {
            // Always include every period so the x-axis shows all days/months, not just ones with data
            let bidsAmt   = bidsBuckets[period]   ?? 0
            let offersAmt = offersBuckets[period] ?? 0
            result.append(DetailedSpendData(id: "\(period)-Bids",   period: period, amount: bidsAmt,   source: "Bids Won"))
            result.append(DetailedSpendData(id: "\(period)-Offers", period: period, amount: offersAmt, source: "Accepted Offers"))
        }
        detailedSpendData = result
    }

    // MARK: - Period label for a single transaction date
    private func periodLabel(for date: Date, calendar: Calendar, now: Date) -> String {
        switch selectedTimeframe {
        case "Week":
            return buyerPerfDayFormatter.string(from: date)

        case "Year":
            return buyerPerfMonthFormatter.string(from: date)

        default:
            let dayOfMonth = calendar.component(.day, from: date)
            switch dayOfMonth {
            case 1...7:   return "Week 1"
            case 8...14:  return "Week 2"
            case 15...21: return "Week 3"
            default:      return "Week 4"
            }
        }
    }

    // MARK: - Ordered x-axis labels
    private func orderedPeriodLabels(calendar: Calendar, now: Date) -> [String] {
        switch selectedTimeframe {
        case "Week":
            return (0..<7).compactMap { offset in
                calendar.date(byAdding: .day, value: -(6 - offset), to: calendar.startOfDay(for: now))
                    .map { buyerPerfDayFormatter.string(from: $0) }
            }

        case "Year":
            return (0..<12).compactMap { offset in
                calendar.date(byAdding: .month, value: -(11 - offset), to: now)
                    .map { buyerPerfMonthFormatter.string(from: $0) }
            }

        default:
            return ["Week 1", "Week 2", "Week 3", "Week 4"]
        }
    }

    // MARK: - Dynamic Insights
    private func updateInsights(windowTransactions: [Transaction]) {
        let offersSpend = detailedSpendData.filter { $0.source == "Accepted Offers" }.reduce(0) { $0 + $1.amount }
        let offerPct    = totalSpend > 0 ? Int((offersSpend / totalSpend) * 100) : 0

        insightOfferRelianceDesc = offerPct > 0
            ? "You sourced \(offerPct)% of your spend this period from direct offers. Try more auctions for competitive pricing."
            : "No offer spend this period. Accept a seller's pitch to diversify your sourcing."

        let marketBaseline: Double = 105.0
        if !windowTransactions.isEmpty {
            let avgPricePerNut = windowTransactions.reduce(0.0) { $0 + $1.pricePerNut } / Double(windowTransactions.count)
            let diffPct = ((avgPricePerNut - marketBaseline) / marketBaseline) * 100
            insightSourcingDesc = diffPct <= 0
                ? "Your average cost is \(String(format: "%.1f", abs(diffPct)))% below the market average (Rs \(Int(marketBaseline)) per nut). Great sourcing."
                : "Your average cost is \(String(format: "%.1f", diffPct))% above market this period. Bid on more auctions for better deals."
        } else {
            insightSourcingDesc = "No completed contracts this period. Finish a purchase to see sourcing insights."
        }

        switch winRate {
        case 0:
            insightBidSuccessDesc = "No bids placed this period. Start bidding on active harvest lots to see your win rate."
        case 1...40:
            insightBidSuccessDesc = "Your win rate is \(winRate)% this period. Try raising your bids by Rs 2–5 to stay ahead."
        case 41...70:
            insightBidSuccessDesc = "Your win rate is \(winRate)% this period. Good — keep an eye on active lots for more opportunities."
        default:
            insightBidSuccessDesc = "Your win rate is \(winRate)% this period. Excellent — you are consistently outbidding the competition."
        }
    }
}
