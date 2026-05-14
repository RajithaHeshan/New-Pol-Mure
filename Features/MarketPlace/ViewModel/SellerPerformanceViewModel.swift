import SwiftUI
import FirebaseFirestore

private final class PerformanceListenerBox {
    var listener: ListenerRegistration?
    init() {}
    deinit { listener?.remove() }
}

private let perfDayFormatter: DateFormatter = {
    let f = DateFormatter(); f.dateFormat = "EEE"; return f
}()

private let perfMonthFormatter: DateFormatter = {
    let f = DateFormatter(); f.dateFormat = "MMM"; return f
}()

@Observable
@MainActor
class SellerPerformanceViewModel {

  
    var selectedTimeframe = "Month"
    let timeframes = ["Week", "Month", "Year"]

    var nutsSold: Int         = 0
    var pitchSuccessRate: Int = 0

    // MARK: - Chart Data
    var detailedRevenueData: [DetailedRevenueData] = []

    // MARK: - Dynamic KPI (computed from filtered chart data)
    var totalRevenue: Double {
        detailedRevenueData.reduce(0) { $0 + $1.amount }
    }

    var hasNoRevenueData: Bool {
        detailedRevenueData.allSatisfy { $0.amount == 0 }
    }

    // MARK: - Dynamic Insights
    var insightPremiumDesc: String = "Analysing your pricing position…"
    var insightPitchDesc: String   = "Analysing your revenue mix…"
    var insightEscrowDesc: String  = "Analysing escrow turnaround…"

    // MARK: - Loading State
    var isLoading = false

    private let currentSellerID: String

    // Raw fetched data — kept as all-time; re-filtered on timeframe change
    private var allTransactions: [Transaction] = []
    private var allOffers:       [Offer]       = []

    private let transactionsListenerBox = PerformanceListenerBox()
    private let offersListenerBox       = PerformanceListenerBox()

    init() {
        self.currentSellerID = AuthManager.shared.currentUserID
        if currentSellerID.isEmpty {
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self.attachTransactionsListener()
                self.attachOffersListener()
            }
        } else {
            attachTransactionsListener()
            attachOffersListener()
        }
    }

    func onTimeframeChanged() {
        recompute()
    }

//selected time frame week/year
    private func windowStart(calendar: Calendar, now: Date) -> Date {
        switch selectedTimeframe {
        case "Week":  return calendar.date(byAdding: .day,   value: -6,  to: calendar.startOfDay(for: now)) ?? now
        case "Year":  return calendar.date(byAdding: .month, value: -11, to: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!) ?? now
        default:      return calendar.date(from: calendar.dateComponents([.year, .month], from: now))! // start of current month
        }
    }

   //attached transaction 

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
                    print("Seller performance transactions error: \(error.localizedDescription)")
                    self.isLoading = false; return
                }
                self.allTransactions = snapshot?.documents.compactMap {
                    Transaction(id: $0.documentID, data: $0.data())
                } ?? []
                self.recompute()
                self.isLoading = false
            }
    }



    private func attachOffersListener() {
        guard !currentSellerID.isEmpty else { return }

        offersListenerBox.listener = Firestore.firestore()
            .collection("offers")
            .whereField("sellerID", isEqualTo: currentSellerID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("Seller performance offers error: \(error.localizedDescription)")
                    return
                }
                self.allOffers = snapshot?.documents.compactMap {
                    Offer(id: $0.documentID, data: $0.data())
                } ?? []
                self.recompute()
            }
    }

    // MARK: - Central recompute — called whenever data or timeframe changes
    private func recompute() {
        let calendar = Calendar.current
        let now      = Date()
        let start    = windowStart(calendar: calendar, now: now)

        // Filter by completedAt (when money actually moved) — accurate across month boundaries
        let windowTransactions = allTransactions.filter { $0.completedAt >= start }
        let windowOffers       = allOffers.filter       { $0.placedAt    >= start }

        // Nuts sold = sum of quantities from window transactions (completedAt is accurate)
        nutsSold = windowTransactions.reduce(0) { $0 + $1.quantity }

        // Pitch success rate = accepted pitches / total pitches in window
        let totalPitches    = windowOffers.count
        let acceptedPitches = windowOffers.filter { $0.status == "accepted" }.count
        pitchSuccessRate = totalPitches > 0 ? Int((Double(acceptedPitches) / Double(totalPitches)) * 100) : 0

        // Chart data
        recomputeChartData(transactions: windowTransactions, calendar: calendar, now: now)

        // Insights
        updateInsights(windowTransactions: windowTransactions)
    }

    // MARK: - Chart bucket grouping
    private func recomputeChartData(transactions: [Transaction], calendar: Calendar, now: Date) {
        var auctionBuckets: [String: Double] = [:]
        var pitchBuckets:   [String: Double] = [:]

        for tx in transactions {
            let key = periodLabel(for: tx.completedAt, calendar: calendar, now: now)
            if tx.source == "offer" {
                pitchBuckets[key, default: 0] += tx.amount
            } else {
                auctionBuckets[key, default: 0] += tx.amount
            }
        }

        let periods = orderedPeriodLabels(calendar: calendar, now: now)
        var result: [DetailedRevenueData] = []
        for period in periods {
            // Always include every period so the x-axis shows all days/months, not just ones with data
            let auctionAmt = auctionBuckets[period] ?? 0
            let pitchAmt   = pitchBuckets[period]   ?? 0
            result.append(DetailedRevenueData(id: "\(period)-Auction", period: period, amount: auctionAmt, source: "Auction Sales"))
            result.append(DetailedRevenueData(id: "\(period)-Pitch",   period: period, amount: pitchAmt,   source: "Accepted Pitches"))
        }
        detailedRevenueData = result
    }

    // MARK: - Period label for a single transaction date
    private func periodLabel(for date: Date, calendar: Calendar, now: Date) -> String {
        switch selectedTimeframe {
        case "Week":
            return perfDayFormatter.string(from: date)

        case "Year":
            return perfMonthFormatter.string(from: date)

        default: // Month — week-of-month buckets
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
            // Last 7 days oldest → newest
            return (0..<7).compactMap { offset in
                calendar.date(byAdding: .day, value: -(6 - offset), to: calendar.startOfDay(for: now))
                    .map { perfDayFormatter.string(from: $0) }
            }

        case "Year":
            // Last 12 calendar months oldest → newest
            return (0..<12).compactMap { offset in
                calendar.date(byAdding: .month, value: -(11 - offset), to: now)
                    .map { perfMonthFormatter.string(from: $0) }
            }

        default:
            return ["Week 1", "Week 2", "Week 3", "Week 4"]
        }
    }

    // MARK: - Dynamic Insights
    private func updateInsights(windowTransactions: [Transaction]) {
        let pitchRevenue = detailedRevenueData.filter { $0.source == "Accepted Pitches" }.reduce(0) { $0 + $1.amount }
        let pitchPct     = totalRevenue > 0 ? Int((pitchRevenue / totalRevenue) * 100) : 0

        insightPitchDesc = pitchPct > 0
            ? "\(pitchPct)% of your revenue this period comes from direct pitches. Check the Urgent Board for new buyer needs."
            : "No pitch revenue this period. Try placing offers on the Urgent Board to diversify your income."

        let marketBaseline: Double = 105.0
        if !windowTransactions.isEmpty {
            let avgPricePerNut = windowTransactions.reduce(0.0) { $0 + $1.pricePerNut } / Double(windowTransactions.count)
            let diffPct = ((avgPricePerNut - marketBaseline) / marketBaseline) * 100
            insightPremiumDesc = diffPct >= 0
                ? "You sold \(String(format: "%.1f", diffPct))% above the market average (Rs \(Int(marketBaseline)) per nut) this period. Strong pricing."
                : "Your average price is \(String(format: "%.1f", abs(diffPct)))% below the market average this period. Try setting a higher starting bid."
        } else {
            insightPremiumDesc = "No completed contracts this period. Complete a sale to see pricing insights."
        }

        insightEscrowDesc = windowTransactions.isEmpty
            ? "No completed contracts this period. Escrow data will appear after your first sale."
            : "You completed \(windowTransactions.count) transaction(s) this period. Ask buyers to complete inspection quickly to release escrow faster."
    }
}
