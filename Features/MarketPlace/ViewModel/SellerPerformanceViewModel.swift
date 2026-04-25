// Location: New-Pol-Mure/Features/Marketplace/ViewModels/SellerPerformanceViewModel.swift

import SwiftUI
import FirebaseFirestore

private final class PerformanceListenerBox {
    var listener: ListenerRegistration?
    init() {}
    deinit { listener?.remove() }
}

@Observable
@MainActor
class SellerPerformanceViewModel {

    // MARK: - Timeframe Picker
    var selectedTimeframe = "Month"
    let timeframes = ["Week", "Month", "Year"]

    // MARK: - KPI Values
    var nutsSold: Int        = 0
    var pitchSuccessRate: Int = 0  // percentage

    // MARK: - Chart Data (computed on demand from raw transactions)
    var detailedRevenueData: [DetailedRevenueData] = []

    // MARK: - Dynamic KPI
    var totalRevenue: Double {
        detailedRevenueData.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Dynamic Insights
    var insightPremiumDesc: String  = "Analysing your pricing position…"
    var insightPitchDesc: String    = "Analysing your revenue mix…"
    var insightEscrowDesc: String   = "Analysing escrow turnaround…"

    // MARK: - Loading State
    var isLoading = false

    private let currentSellerID: String

    // Raw fetched data — re-processed whenever selectedTimeframe changes
    private var allTransactions: [Transaction] = [] {
        didSet { recomputeChartData() }
    }

    private let transactionsListenerBox = PerformanceListenerBox()
    private let contractsListenerBox    = PerformanceListenerBox()
    private let offersListenerBox       = PerformanceListenerBox()

    init() {
        self.currentSellerID = AuthManager.shared.currentUserID
        attachTransactionsListener()
        attachContractsListener()
        attachOffersListener()
    }

    // MARK: - Timeframe change triggers chart recompute
    func onTimeframeChanged() {
        recomputeChartData()
    }

    // MARK: - Tab 1: Transactions Listener (drives revenue chart + total)
    private func attachTransactionsListener() {
        guard !currentSellerID.isEmpty else { return }
        isLoading = true

        transactionsListenerBox.listener = Firestore.firestore()
            .collection("transactions")
            .whereField("sellerID", isEqualTo: currentSellerID)
            .whereField("isCredit", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Performance transactions listener error: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }

                self.allTransactions = snapshot?.documents.compactMap {
                    Transaction(id: $0.documentID, data: $0.data())
                } ?? []

                self.isLoading = false
            }
    }

    // MARK: - Contracts Listener (drives Nuts Sold KPI)
    private func attachContractsListener() {
        guard !currentSellerID.isEmpty else { return }

        contractsListenerBox.listener = Firestore.firestore()
            .collection("contracts")
            .whereField("sellerID", isEqualTo: currentSellerID)
            .whereField("status", isEqualTo: "completed")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Performance contracts listener error: \(error.localizedDescription)")
                    return
                }

                let completed = snapshot?.documents.compactMap {
                    Contract(id: $0.documentID, data: $0.data())
                } ?? []

                // Nuts sold = sum of quantities stored on completed contracts
                self.nutsSold = completed.reduce(0) {
                    $0 + (($1.amount > 0) ? Int($1.amount) : 0)
                }

                self.updateInsights(completedContracts: completed)
            }
    }

    // MARK: - Offers Listener (drives Pitch Success Rate KPI)
    private func attachOffersListener() {
        guard !currentSellerID.isEmpty else { return }

        offersListenerBox.listener = Firestore.firestore()
            .collection("offers")
            .whereField("sellerID", isEqualTo: currentSellerID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Performance offers listener error: \(error.localizedDescription)")
                    return
                }

                let offers = snapshot?.documents.compactMap {
                    Offer(id: $0.documentID, data: $0.data())
                } ?? []

                let total    = offers.count
                let accepted = offers.filter { $0.amount > 0 }.count  // all placed offers count as active pitches

                // Pitch success = (accepted / total) * 100; fallback 0 if no offers yet
                self.pitchSuccessRate = total > 0 ? Int((Double(accepted) / Double(total)) * 100) : 0
            }
    }

    // MARK: - Recompute chart data for the selected timeframe
    private func recomputeChartData() {
        let calendar  = Calendar.current
        let now       = Date()

        // Group credit transactions into (period, source) buckets
        var auctionBuckets: [String: Double] = [:]
        var pitchBuckets:   [String: Double] = [:]

        for tx in allTransactions {
            let periodKey = periodLabel(for: tx.completedAt, calendar: calendar, now: now)
            guard !periodKey.isEmpty else { continue }

            if tx.source == "offer" {
                pitchBuckets[periodKey, default: 0] += tx.amount
            } else {
                auctionBuckets[periodKey, default: 0] += tx.amount
            }
        }

        let orderedPeriods = orderedPeriodLabels(calendar: calendar, now: now)

        var result: [DetailedRevenueData] = []
        for period in orderedPeriods {
            let auctionAmt = auctionBuckets[period] ?? 0
            let pitchAmt   = pitchBuckets[period]   ?? 0
            if auctionAmt > 0 {
                result.append(DetailedRevenueData(id: "\(period)-Auction", period: period, amount: auctionAmt, source: "Auction Sales"))
            }
            if pitchAmt > 0 {
                result.append(DetailedRevenueData(id: "\(period)-Pitch", period: period, amount: pitchAmt, source: "Accepted Pitches"))
            }
            // If no data for this period, omit it — chart will skip the gap naturally
        }

        detailedRevenueData = result
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
        // Pitch dependency = pitches revenue / total revenue
        let pitchRevenue   = detailedRevenueData.filter { $0.source == "Accepted Pitches" }.reduce(0) { $0 + $1.amount }
        let pitchPct       = totalRevenue > 0 ? Int((pitchRevenue / totalRevenue) * 100) : 0

        insightPitchDesc = pitchPct > 0
            ? "\(pitchPct)% of your revenue comes from direct pitches. Keep checking the Urgent Board for new buyer needs."
            : "No pitch revenue recorded yet. Start placing offers on the Urgent Board to diversify income."

        // Premium pricing — compare seller's average against a fixed market baseline (Rs 105)
        let marketBaseline: Double = 105.0
        let avgAmount = completedContracts.isEmpty ? 0 : completedContracts.reduce(0) { $0 + $1.amount } / Double(completedContracts.count)
        if avgAmount > 0 {
            let diffPct = ((avgAmount - marketBaseline) / marketBaseline) * 100
            if diffPct > 0 {
                insightPremiumDesc = "You are selling \(String(format: "%.1f", diffPct))% above the Kurunegala market average. Strong pricing position."
            } else {
                insightPremiumDesc = "Your average price is \(String(format: "%.1f", abs(diffPct)))% below the Kurunegala market average. Consider adjusting bids."
            }
        } else {
            insightPremiumDesc = "No completed contracts yet. Complete your first sale to see pricing insights."
        }

        // Escrow delays — placeholder insight until escrow timestamps are tracked
        insightEscrowDesc = completedContracts.isEmpty
            ? "No completed contracts yet. Escrow turnaround data will appear here after your first sale."
            : "You have \(completedContracts.count) completed contract(s) this period. Remind buyers to inspect quickly to release escrow faster."
    }
}
