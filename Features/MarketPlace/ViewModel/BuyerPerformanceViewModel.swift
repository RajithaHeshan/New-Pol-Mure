// Location: New-Pol-Mure/Features/MarketPlace/ViewModels/BuyerPerformanceViewModel.swift

import SwiftUI
import FirebaseFirestore

private final class BuyerPerformanceListenerBox {
    var listener: ListenerRegistration?
    init() {}
    deinit { listener?.remove() }
}

@Observable
@MainActor
class BuyerPerformanceViewModel {

    // MARK: - Timeframe Picker
    var selectedTimeframe = "Month"
    let timeframes = ["Week", "Month", "Year"]

    // MARK: - KPI Values
    var totalVolumeNuts: Int = 0
    var winRate: Int         = 0  // percentage

    // MARK: - Chart Data (computed on demand from raw transactions)
    var detailedSpendData: [DetailedSpendData] = []

    // MARK: - Dynamic KPI
    var totalSpend: Double {
        detailedSpendData.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Dynamic Insights
    var insightSourcingDesc: String   = "Analysing your acquisition cost…"
    var insightBidSuccessDesc: String = "Analysing your bid win rate…"
    var insightOfferRelianceDesc: String = "Analysing your spend mix…"

    // MARK: - Loading State
    var isLoading = false

    private let currentBuyerID: String

    // Raw fetched data — re-processed whenever selectedTimeframe changes
    private var allTransactions: [Transaction] = [] {
        didSet { recomputeChartData() }
    }

    private let transactionsListenerBox = BuyerPerformanceListenerBox()
    private let contractsListenerBox    = BuyerPerformanceListenerBox()
    private let bidsListenerBox         = BuyerPerformanceListenerBox()

    init() {
        self.currentBuyerID = AuthManager.shared.currentUserID
        attachTransactionsListener()
        attachContractsListener()
        attachBidsListener()
    }

    // MARK: - Timeframe change triggers chart recompute
    func onTimeframeChanged() {
        recomputeChartData()
    }

    // MARK: - Transactions Listener (drives spend chart + total)
    private func attachTransactionsListener() {
        guard !currentBuyerID.isEmpty else { return }
        isLoading = true

        transactionsListenerBox.listener = Firestore.firestore()
            .collection("transactions")
            .whereField("buyerID", isEqualTo: currentBuyerID)
            .whereField("isCredit", isEqualTo: false)   // buyer payments = outgoing
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Buyer performance transactions listener error: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }

                self.allTransactions = snapshot?.documents.compactMap {
                    Transaction(id: $0.documentID, data: $0.data())
                } ?? []

                self.isLoading = false
            }
    }

    // MARK: - Contracts Listener (drives Total Volume KPI)
    private func attachContractsListener() {
        guard !currentBuyerID.isEmpty else { return }

        contractsListenerBox.listener = Firestore.firestore()
            .collection("contracts")
            .whereField("buyerID", isEqualTo: currentBuyerID)
            .whereField("status", isEqualTo: "completed")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Buyer performance contracts listener error: \(error.localizedDescription)")
                    return
                }

                let completed = snapshot?.documents.compactMap {
                    Contract(id: $0.documentID, data: $0.data())
                } ?? []

                // Volume = count of completed contracts (quantity not separately stored on contract)
                self.totalVolumeNuts = completed.count

                self.updateInsights(completedContracts: completed)
            }
    }

    // MARK: - Bids Listener (drives Win Rate KPI)
    private func attachBidsListener() {
        guard !currentBuyerID.isEmpty else { return }

        bidsListenerBox.listener = Firestore.firestore()
            .collection("bids")
            .whereField("bidderID", isEqualTo: currentBuyerID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Buyer performance bids listener error: \(error.localizedDescription)")
                    return
                }

                let allBids = snapshot?.documents.compactMap {
                    Bid(id: $0.documentID, data: $0.data())
                } ?? []

                // Group bids by sellerID and check if this buyer holds the highest bid per seller
                var highestPerSeller: [String: Double] = [:]
                for bid in allBids {
                    if (highestPerSeller[bid.sellerID] ?? 0) < bid.amount {
                        highestPerSeller[bid.sellerID] = bid.amount
                    }
                }

                // Win = buyer's bid equals the highest bid on that seller's lot
                let myBidsBySeller: [String: Double] = allBids.reduce(into: [:]) { map, bid in
                    if (map[bid.sellerID] ?? 0) < bid.amount {
                        map[bid.sellerID] = bid.amount
                    }
                }

                let totalLots = myBidsBySeller.count
                let wonLots   = myBidsBySeller.filter { sellerID, myTop in
                    highestPerSeller[sellerID] == myTop
                }.count

                self.winRate = totalLots > 0 ? Int((Double(wonLots) / Double(totalLots)) * 100) : 0
            }
    }

    // MARK: - Recompute chart data for the selected timeframe
    private func recomputeChartData() {
        let calendar = Calendar.current
        let now      = Date()

        var bidsBuckets:   [String: Double] = [:]
        var offersBuckets: [String: Double] = [:]

        for tx in allTransactions {
            let periodKey = periodLabel(for: tx.completedAt, calendar: calendar, now: now)
            guard !periodKey.isEmpty else { continue }

            if tx.source == "offer" {
                offersBuckets[periodKey, default: 0] += tx.amount
            } else {
                bidsBuckets[periodKey, default: 0] += tx.amount
            }
        }

        let orderedPeriods = orderedPeriodLabels(calendar: calendar, now: now)

        var result: [DetailedSpendData] = []
        for period in orderedPeriods {
            let bidsAmt   = bidsBuckets[period]   ?? 0
            let offersAmt = offersBuckets[period] ?? 0
            if bidsAmt > 0 {
                result.append(DetailedSpendData(id: "\(period)-Bids", period: period, amount: bidsAmt, source: "Bids Won"))
            }
            if offersAmt > 0 {
                result.append(DetailedSpendData(id: "\(period)-Offers", period: period, amount: offersAmt, source: "Accepted Offers"))
            }
        }

        detailedSpendData = result
    }

    // MARK: - Period label for a transaction date given the selected timeframe
    private func periodLabel(for date: Date, calendar: Calendar, now: Date) -> String {
        switch selectedTimeframe {
        case "Week":
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            guard date >= startOfWeek else { return "" }
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEE"
            return dayFormatter.string(from: date)

        case "Year":
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            guard date >= startOfYear else { return "" }
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM"
            return monthFormatter.string(from: date)

        default: // "Month"
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            guard date >= startOfMonth else { return "" }
            let dayOfMonth = calendar.component(.day, from: date)
            switch dayOfMonth {
            case 1...7:   return "Week 1"
            case 8...14:  return "Week 2"
            case 15...21: return "Week 3"
            default:      return "Week 4"
            }
        }
    }

    // MARK: - Ordered period label list for the chart x-axis
    private func orderedPeriodLabels(calendar: Calendar, now: Date) -> [String] {
        switch selectedTimeframe {
        case "Week":
            return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        case "Year":
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM"
            return (0..<12).compactMap {
                calendar.date(byAdding: .month, value: -11 + $0, to: now).map { monthFormatter.string(from: $0) }
            }
        default:
            return ["Week 1", "Week 2", "Week 3", "Week 4"]
        }
    }

    // MARK: - Dynamic Insight Text
    private func updateInsights(completedContracts: [Contract]) {
        // Offer reliance = offers spend / total spend
        let offersSpend  = detailedSpendData.filter { $0.source == "Accepted Offers" }.reduce(0) { $0 + $1.amount }
        let offerPct     = totalSpend > 0 ? Int((offersSpend / totalSpend) * 100) : 0

        insightOfferRelianceDesc = offerPct > 0
            ? "You acquire \(offerPct)% of your volume from direct offers. Try more auctions for competitive pricing."
            : "No offer spend recorded yet. Accept a seller's pitch to diversify your sourcing mix."

        // Sourcing cost — compare buyer's avg contract amount vs a market baseline (Rs 105 per nut)
        let marketBaseline: Double = 105.0
        let avgAmount = completedContracts.isEmpty ? 0 : completedContracts.reduce(0) { $0 + $1.amount } / Double(completedContracts.count)
        if avgAmount > 0 {
            let diffPct = ((avgAmount - marketBaseline) / marketBaseline) * 100
            if diffPct < 0 {
                insightSourcingDesc = "Your average acquisition cost is \(String(format: "%.1f", abs(diffPct)))% below market average. Excellent sourcing."
            } else {
                insightSourcingDesc = "Your average acquisition cost is \(String(format: "%.1f", diffPct))% above market average. Consider bidding on more auctions."
            }
        } else {
            insightSourcingDesc = "No completed contracts yet. Complete your first purchase to see sourcing insights."
        }

        // Bid success feedback
        switch winRate {
        case 0:
            insightBidSuccessDesc = "No bids placed yet. Start bidding on active harvest lots to see your win rate."
        case 1...40:
            insightBidSuccessDesc = "Your bid win rate is \(winRate)%. Consider increasing offers by Rs 2–5 to stay competitive."
        case 41...70:
            insightBidSuccessDesc = "Your bid win rate is \(winRate)%. Solid performance — keep monitoring active lots for opportunities."
        default:
            insightBidSuccessDesc = "Your bid win rate is \(winRate)%. Excellent — you are consistently outbidding the competition."
        }
    }
}
