import SwiftUI
import FirebaseFirestore
import CoreLocation

// area 
struct CoconutZone: Identifiable, Hashable {
    let id: String        
    let displayName: String
    let centerLat: Double
    let centerLng: Double
    let radiusKM: Double

    func contains(lat: Double, lng: Double) -> Bool {
        let a = CLLocation(latitude: centerLat, longitude: centerLng)
        let b = CLLocation(latitude: lat, longitude: lng)
        return (a.distance(from: b) / 1000.0) <= radiusKM
    }

    static let allZones: [CoconutZone] = [
        CoconutZone(id: "all",           displayName: "All Sri Lanka",  centerLat: 7.8731,  centerLng: 80.7718, radiusKM: 999),
        CoconutZone(id: "kurunegala",    displayName: "Kurunegala",     centerLat: 7.4818,  centerLng: 80.3609, radiusKM: 40),
        CoconutZone(id: "kandy",         displayName: "Kandy",          centerLat: 7.2906,  centerLng: 80.6337, radiusKM: 35),
        CoconutZone(id: "colombo",       displayName: "Colombo",        centerLat: 6.9271,  centerLng: 79.8612, radiusKM: 35),
        CoconutZone(id: "gampaha",       displayName: "Gampaha",        centerLat: 7.0917,  centerLng: 80.0000, radiusKM: 35),
        CoconutZone(id: "matale",        displayName: "Matale",         centerLat: 7.4675,  centerLng: 80.6234, radiusKM: 35),
        CoconutZone(id: "puttalam",      displayName: "Puttalam",       centerLat: 8.0362,  centerLng: 79.8283, radiusKM: 40),
        CoconutZone(id: "kegalle",       displayName: "Kegalle",        centerLat: 7.2513,  centerLng: 80.3464, radiusKM: 35),
        CoconutZone(id: "galle",         displayName: "Galle",          centerLat: 6.0535,  centerLng: 80.2210, radiusKM: 35),
        CoconutZone(id: "anuradhapura",  displayName: "Anuradhapura",   centerLat: 8.3114,  centerLng: 80.4037, radiusKM: 45),
        CoconutZone(id: "ratnapura",     displayName: "Ratnapura",      centerLat: 6.6828,  centerLng: 80.3992, radiusKM: 35),
    ]

    
    static func zone(for lat: Double, lng: Double) -> CoconutZone {
        let point = CLLocation(latitude: lat, longitude: lng)
        return allZones
            .filter { $0.id != "all" && $0.contains(lat: lat, lng: lng) }
            .min(by: {
                let a = CLLocation(latitude: $0.centerLat, longitude: $0.centerLng)
                let b = CLLocation(latitude: $1.centerLat, longitude: $1.centerLng)
                return a.distance(from: point) < b.distance(from: point)
            })
            ?? allZones[0]
    }
}



private let dayFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "EEE"
    return f
}()

//  day show on chart 
private let chartTickFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "d MMM"
    return f
}()

// date show in the chart 
private let fullDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "d MMM yyyy"
    return f
}()

private final class AnalyticsListenerBox {
    var listener: ListenerRegistration?
    init() {}
    deinit { listener?.remove() }
}



@Observable
@MainActor
class MarketAnalyticsViewModel {

   
    var selectedZone: CoconutZone = CoconutZone.allZones[0]
    let zones = CoconutZone.allZones


    var priceHistory: [PriceTrend] = []

  
    var currentMarketAverage: Double  = 0
    var weeklyChangePercent: Double   = 0
    var prevWeekAverage: Double       = 0   // previous 7-day avg — fed into PriceForecastEngine
    var weeklyTransactionCount: Int   = 0   // total bids+offers this week in selected zone



    
    private var thisWeekTrueAverage: Double = 0

    
    var chartDateRange: String = ""

    
    var priceForecast: PriceForecast? = nil


    var marketInsight: String = "Analysing market trends…"

    // Loading State
    var isLoading = false

   
    private var allBids: [Bid] = []
    private var allOffers: [Offer] = []
   
    private var sellerLocations: [String: (lat: Double, lng: Double)] = [:]
    
    private var harvestLocations: [String: (lat: Double, lng: Double)] = [:]

    private let bidsListenerBox     = AnalyticsListenerBox()
    private let offersListenerBox   = AnalyticsListenerBox()
    private let sellersListenerBox  = AnalyticsListenerBox()
    private let harvestsListenerBox = AnalyticsListenerBox()

    init(preselectedZone: CoconutZone? = nil) {
        if let zone = preselectedZone {
            selectedZone = zone
        } else {
            loadUserZone()
        }
        attachSellersListener()
        attachHarvestLocationsListener()
        attachBidsListener()
        attachOffersListener()
    }





    // Auto-detect zone from logged-in user's registered location
    private func loadUserZone() {
        let userID = AuthManager.shared.currentUserID
        guard !userID.isEmpty else { return }

        Task {
            let doc = try? await Firestore.firestore().collection("users").document(userID).getDocument()
            guard
                let data = doc?.data(),
                let lat  = data["latitude"]  as? Double,
                let lng  = data["longitude"] as? Double
            else { return }

            let detected = CoconutZone.zone(for: lat, lng: lng)
            self.selectedZone = detected
            self.recomputeTrend()
        }
    }




    // Sellers listener — keeps sellerID 

    private func attachSellersListener() {
        sellersListenerBox.listener = Firestore.firestore()
            .collection("users")
            .whereField("role", isEqualTo: "SELLER")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }
                var map: [String: (Double, Double)] = [:]
                for doc in docs {
                    let d = doc.data()
                    if let lat = d["latitude"] as? Double, let lng = d["longitude"] as? Double {
                        map[doc.documentID] = (lat, lng)
                    }
                }
                self.sellerLocations = map
                self.recomputeTrend()
            }
    }

    


    private func attachHarvestLocationsListener() {
        harvestsListenerBox.listener = Firestore.firestore()
            .collection("harvestLots")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }
                var map: [String: (Double, Double)] = [:]
                for doc in docs {
                    let d = doc.data()
                    if let lat = d["latitude"] as? Double, let lng = d["longitude"] as? Double {
                        map[doc.documentID] = (lat, lng)
                    }
                }
                self.harvestLocations = map
                self.recomputeTrend()
            }
    }

    // Bids listener — last 14 days 
    private func attachBidsListener() {
        isLoading = true
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
                self.allBids = snapshot?.documents.compactMap {
                    Bid(id: $0.documentID, data: $0.data())
                } ?? []
                self.recomputeTrend()
                self.isLoading = false
            }
    }



    // MARK: - Offers listener — last 14 days 
    private func attachOffersListener() {
        let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()

        offersListenerBox.listener = Firestore.firestore()
            .collection("offers")
            .whereField("placedAt", isGreaterThan: Timestamp(date: fourteenDaysAgo))
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("Analytics offers listener error: \(error.localizedDescription)")
                    return
                }
                self.allOffers = snapshot?.documents.compactMap {
                    Offer(id: $0.documentID, data: $0.data())
                } ?? []
                self.recomputeTrend()
            }
    }



    //  Called whenever zone changes or new data arrives
    func recomputeTrend() {
        // Merge bids and offers 
        var pricePoints: [(sellerID: String, amount: Double, date: Date)] = []

        if selectedZone.id == "all" {
            pricePoints += allBids.map   { ($0.sellerID, $0.amount, $0.placedAt) }
            pricePoints += allOffers.map { ($0.sellerID, $0.amount, $0.placedAt) }
        } else {
            pricePoints += allBids.compactMap { bid in
                // Use harvest lot coordinates if available — harvest may be in a different
                // district than the seller's registered home location
                let loc = harvestLocations[bid.harvestID] ?? sellerLocations[bid.sellerID]
                guard let loc, selectedZone.contains(lat: loc.lat, lng: loc.lng) else { return nil }
                return (bid.sellerID, bid.amount, bid.placedAt)
            }


            pricePoints += allOffers.compactMap { offer in
                guard let loc = sellerLocations[offer.sellerID],
                      selectedZone.contains(lat: loc.lat, lng: loc.lng) else { return nil }
                return (offer.sellerID, offer.amount, offer.placedAt)
            }
        }

        computeTrend(from: pricePoints)
    }




   // seven day price trend 7 days thrue avaerage

    private func computeTrend(from points: [(sellerID: String, amount: Double, date: Date)]) {
        let calendar = Calendar.current
        let today    = calendar.startOfDay(for: Date())

        var thisWeekTotals: [Int: (sum: Double, count: Int)] = [:]
        var prevWeekTotals: [Int: (sum: Double, count: Int)] = [:]

        for point in points {
            let bidDay = calendar.startOfDay(for: point.date)
            let offset = calendar.dateComponents([.day], from: bidDay, to: today).day ?? 999

            if offset >= 0 && offset < 7 {
                let existing = thisWeekTotals[offset] ?? (0, 0)
                thisWeekTotals[offset] = (existing.sum + point.amount, existing.count + 1)
            } else if offset >= 7 && offset < 14 {
                let key      = offset - 7
                let existing = prevWeekTotals[key] ?? (0, 0)
                prevWeekTotals[key] = (existing.sum + point.amount, existing.count + 1)
            }
        }

        var trends: [PriceTrend] = []
        for offset in stride(from: 6, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let dayLabel  = dayFormatter.string(from: date)       // "Thu"
            let tickLabel = chartTickFormatter.string(from: date)  // "24 Apr"
            let avg: Double
            if let entry = thisWeekTotals[offset], entry.count > 0 {
                avg = entry.sum / Double(entry.count)
            } else {
                avg = trends.last?.price ?? 0
            }
            trends.append(PriceTrend(id: tickLabel, day: dayLabel, date: date, price: avg))
        }

        priceHistory = trends

        // Date range label — "24 Apr 2026 – 30 Apr 2026"
        if let first = trends.first?.date, let last = trends.last?.date {
            chartDateRange = "\(fullDateFormatter.string(from: first)) – \(fullDateFormatter.string(from: last))"
        }

        // Use today's average (offset 0) if it has bids, otherwise fall back to most recent day with data
        if let todayEntry = thisWeekTotals[0], todayEntry.count > 0 {
            currentMarketAverage = todayEntry.sum / Double(todayEntry.count)
        } else if let latest = trends.last(where: { $0.price > 0 }) {
            currentMarketAverage = latest.price
        } else {
            currentMarketAverage = 0
        }

        let thisWeekAvg = thisWeekTotals.values.reduce((0.0, 0)) { ($0.0 + $1.sum, $0.1 + $1.count) }
        let prevWeekAvg = prevWeekTotals.values.reduce((0.0, 0)) { ($0.0 + $1.sum, $0.1 + $1.count) }

        let prevAvg     = prevWeekAvg.1 > 0 ? prevWeekAvg.0 / Double(prevWeekAvg.1) : 0
        let thisAvg     = thisWeekAvg.1 > 0 ? thisWeekAvg.0 / Double(thisWeekAvg.1) : 0

        // UI shows spot price (today or most recent day) — insight text matches chart header
        weeklyChangePercent    = prevAvg > 0 ? ((currentMarketAverage - prevAvg) / prevAvg) * 100 : 0
        prevWeekAverage        = prevAvg
        weeklyTransactionCount = thisWeekAvg.1
        


        thisWeekTrueAverage    = thisAvg > 0 ? thisAvg : currentMarketAverage

        updateInsight()
        updateForecast() //then next seven days
    }



   
    private func updateInsight() {
        let zoneName   = selectedZone.id == "all" ? "Sri Lanka" : selectedZone.displayName
        let priceStr   = String(format: "%.0f", currentMarketAverage)
        let changeStr  = String(format: "%.1f", abs(weeklyChangePercent))

        if hasNoData {
            marketInsight = "No transactions recorded in \(zoneName) yet. Once buyers and sellers start trading here, you will see live price trends."
            return
        }

        switch weeklyChangePercent {
        case let x where x > 15:
            marketInsight = "Prices in \(zoneName) jumped \(changeStr)% this week and are now at Rs \(priceStr) per nut. If you are a seller, this is a great time to list — demand is high. If you are a buyer, act fast before prices go higher."
        case let x where x > 5:
            marketInsight = "Prices in \(zoneName) are going up — currently Rs \(priceStr) per nut, up \(changeStr)% from last week. Sellers are in a strong position. Buyers should place bids soon."
        case let x where x > 0:
            marketInsight = "Prices in \(zoneName) are slightly higher this week at Rs \(priceStr) per nut (+\(changeStr)%). The market is steady. Both buyers and sellers can trade with confidence."
        case let x where x < -15:
            marketInsight = "Prices in \(zoneName) dropped \(changeStr)% this week to Rs \(priceStr) per nut. Buyers have strong negotiating power right now. Sellers should try to secure a deal quickly to avoid holding stock too long."
        case let x where x < -5:
            marketInsight = "Prices in \(zoneName) are softer this week at Rs \(priceStr) per nut, down \(changeStr)%. Buyers can negotiate better deals. Sellers should pitch early to lock in a buyer before prices drop further."
        case let x where x < 0:
            marketInsight = "Prices in \(zoneName) are slightly lower this week at Rs \(priceStr) per nut (-\(changeStr)%). The market is mostly stable — a reasonable time for both buyers and sellers to make a deal."
        default:
            marketInsight = "Prices in \(zoneName) are stable this week at Rs \(priceStr) per nut. Supply and demand are balanced — a fair time to buy or sell."
        }
    }



// CoreML Forecast seven day price forecasing 
    private func updateForecast() {
        guard !hasNoData else { //no data don't call the model
            priceForecast = nil
            return
        }


 //average calculate        
       
 let modelChangePct = prevWeekAverage > 0
            ? ((thisWeekTrueAverage - prevWeekAverage) / prevWeekAverage) * 100
            : weeklyChangePercent
       
        //training data include in data set 19 in single week

        let clampedTxCount = min(weeklyTransactionCount, 19)
        priceForecast = PriceForecastEngine.shared.predict(
            zoneID:                  selectedZone.id == "all" ? "kurunegala" : selectedZone.id,
            weeklyAvgPrice:          thisWeekTrueAverage,
            prevWeekAvgPrice:        prevWeekAverage,
            weeklyChangePct:         modelChangePct,
            weeklyTransactionCount:  clampedTxCount
        )
    }






//cahart 
  
    var hasNoData: Bool {
        priceHistory.allSatisfy { $0.price == 0 }
    }

    var chartYDomain: ClosedRange<Double> {
        let prices = priceHistory.map { $0.price }.filter { $0 > 0 }
        guard let minP = prices.min(), let maxP = prices.max() else {
            // No data — use a neutral range centred on current average or 100
            let centre = currentMarketAverage > 0 ? currentMarketAverage : 100
            return (centre - 20)...(centre + 20)
        }
        guard minP < maxP else {
            return (minP - 10)...(maxP + 10)
        }
        let padding = (maxP - minP) * 0.2
        return (minP - padding)...(maxP + padding)
    }

    var weeklyChangeLabel: String {
        let sign  = weeklyChangePercent >= 0 ? "+" : ""
        let arrow = weeklyChangePercent >= 0 ? "▲" : "▼"
        return "\(arrow) \(sign)\(String(format: "%.1f", weeklyChangePercent))% from last week"
    }

    var weeklyChangeIsPositive: Bool { weeklyChangePercent >= 0 }

    // Forecast window label — "1 May 2026 – 7 May 2026"
    var forecastDateRange: String {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let endDay   = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return "\(fullDateFormatter.string(from: tomorrow)) – \(fullDateFormatter.string(from: endDay))"
    }
}
