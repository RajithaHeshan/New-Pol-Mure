
import SwiftUI
import MapKit
import FirebaseFirestore
import UserNotifications

@Observable
@MainActor
class DiscoveryDashboardViewModel {

    var searchText = "" {
        didSet { scheduleLocationSearch() } 
    }
  
    var selectedFilter = "All"
    let filters = ["All", "High Volume", "Ending Soon", "Nearest to Me"]

    var showProfile = false
    var showNotifications = false
    var unreadNotificationCount = 3
    var currentUserID: String { AuthManager.shared.currentUserID }

   
    var profileImageName: String = "Gemini_Generated_Image_l5uvm3l5uvm3l5uv"
    var fullName: String = ""
    var monthlySpend: Double = 0.0

    private var monthlySpendListener: ListenerRegistration?

   
    var searchCenter = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609) // Default: Kurunegala
    var searchRadius: Double = 50.0
    var isFullScreenMapPresented = false

  
    var isSearchingLocation = false
    private var searchTask: Task<Void, Never>?

  
    var allSellers: [SellerLocation] = []
    var isLoadingSellers = false
    private var sellersListener: ListenerRegistration?

    // MARK: - Highest Bids Per Seller (sellerID → highest bid amount)
    var highestBids: [String: Double] = [:]
    private var bidsListener: ListenerRegistration?

    // MARK: - Active Harvest Lots (from harvestLots collection)
    var activeHarvests: [HarvestLotItem] = []
    var isLoadingHarvests = false
    private var harvestsListener: ListenerRegistration?

    // MARK: - Seller Ratings Map (sellerID → (averageRating, ratingCount))
    var sellerRatings: [String: (Double, Int)] = [:]
    private var sellerRatingsListener: ListenerRegistration?

    // MARK: - Buyer Profile (used by ML engine)
    private var buyerVolume: Int = 5000
    private var buyerNeedsExport: Bool = false

    // MARK: - Historical Transactions Per Seller (sellerID → count of completed contracts)
    private var historicalTransactions: [String: Int] = [:]
    private var contractsListener: ListenerRegistration?

    // MARK: - ML-Scored Recommendations Cache
    var mlRecommendedSellers: [SellerLocation] = []
    var mlRecommendedHarvests: [HarvestLotItem] = []

    init() {
        fetchUserProfile()
        attachSellersListener()
        attachBidsListener()
        attachHarvestsListener()
        attachSellerRatingsListener()
        attachContractsListener()
        attachMonthlySpendListener()
        requestNotificationPermission()
    }

    // MARK: - Firebase Fetch Logic
    func fetchUserProfile(retryCount: Int = 0) {
        let userId = AuthManager.shared.currentUserID

        // If no session yet, retry up to 5 times with 1s delay (handles Face ID timing gap)
        if userId.isEmpty {
            guard retryCount < 5 else {
                print("⚠️ fetchUserProfile: gave up after 5 retries — no currentUserID")
                return
            }
            print("⚠️ fetchUserProfile: userId empty, retry \(retryCount + 1)/5 in 1s")
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                fetchUserProfile(retryCount: retryCount + 1)
            }
            return
        }

        print("✅ fetchUserProfile: fetching for userId = \(userId)")
        Task {
            do {
                let document = try await Firestore.firestore().collection("users").document(userId).getDocument()
                let data = document.data() ?? [:]

                if let imageName = data["profileImageName"] as? String {
                    self.profileImageName = imageName
                }
                if let name = data["fullName"] as? String {
                    self.fullName = name
                    print("✅ fetchUserProfile: name loaded = \(name)")
                }

                // Decode buyer profile for ML scoring
                if let vol = data["typicalVolume"] as? String {
                    self.buyerVolume = RecommendationEngine.parseVolume(vol)
                }
                self.buyerNeedsExport = (data["needsExport"] as? Bool) ?? false

                // Centre map on buyer's registered location
                if let lat = data["latitude"] as? Double,
                   let lng = data["longitude"] as? Double {
                    self.searchCenter = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                }

                //buyer profile is loaded with correct side
                self.computeMLRecommendations()
            } catch {
                print("Error fetching profile from Firestore: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Monthly Spend Listener (current calendar month, buyer debit transactions)
    private func attachMonthlySpendListener() {
        let buyerID = AuthManager.shared.currentUserID
        guard !buyerID.isEmpty else { return }

        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        monthlySpendListener = Firestore.firestore()
            .collection("transactions")
            .whereField("buyerID", isEqualTo: buyerID)
            .whereField("isCredit", isEqualTo: false)
            .whereField("completedAt", isGreaterThanOrEqualTo: Timestamp(date: monthStart))
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }
                self.monthlySpend = docs.compactMap { $0.data()["amount"] as? Double }.reduce(0, +)
            }
    }

    //Sellers Listener (profile edit section )
    // Replaces one-shot fetch so profile edits (yield, cert, location) appear immediately on the buyer side.
    private func attachSellersListener() {
        isLoadingSellers = true
        sellersListener = Firestore.firestore()
            .collection("users")
            .whereField("role", isEqualTo: "SELLER")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("Sellers listener error: \(error.localizedDescription)")
                    self.isLoadingSellers = false
                    return
                }
                Task {
                    var sellers: [SellerLocation] = []
                    for doc in snapshot?.documents ?? [] {
                        let data = doc.data()
                        guard
                            let name     = data["fullName"]     as? String,
                            let location = data["locationName"] as? String
                        else { continue }

                        let yield         = data["typicalYield"]       as? String ?? "N/A"
                        let cert          = data["certificationLevel"] as? String ?? "Standard"
                        let harvestDate   = (data["nextHarvestDate"] as? Timestamp)?.dateValue() ?? Date()

                        let coordinate: CLLocationCoordinate2D
                        if let lat = data["latitude"] as? Double,
                           let lng = data["longitude"] as? Double {
                            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                        } else {
                            if let resolved = await self.geocode(locationName: location) {
                                coordinate = resolved
                                try? await Firestore.firestore()
                                    .collection("users")
                                    .document(doc.documentID)
                                    .updateData(["latitude": resolved.latitude, "longitude": resolved.longitude])
                            } else { continue }
                        }

                        sellers.append(SellerLocation(
                            id: doc.documentID,
                            sellerName: name,
                            locationName: location,
                            coordinate: coordinate,
                            typicalYield: yield,
                            certificationLevel: cert,
                            nextHarvestDate: harvestDate,
                            averageRating: data["averageRating"] as? Double ?? 0.0,
                            ratingCount:   data["ratingCount"]   as? Int    ?? 0
                        ))
                    }
                    self.allSellers = sellers
                    self.isLoadingSellers = false
                    self.computeMLRecommendations()
                }
            }
    }

    // Bids Listener
    // Groups by sellerID (for registered seller bids) and harvestID (for harvest bids)
    private func attachBidsListener() {
        bidsListener = Firestore.firestore()
            .collection("bids")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }

                var bids: [String: Double] = [:]
                for doc in docs {
                    let data = doc.data()
                    guard let amount = data["amount"] as? Double else { continue }

                    // Index by harvestID for harvest lot bids
                    if let harvestID = data["harvestID"] as? String, !harvestID.isEmpty {
                        if (bids[harvestID] ?? 0) < amount {
                            bids[harvestID] = amount
                        }
                    }
                    // Index by sellerID for registered-seller bids
                    if let sellerID = data["sellerID"] as? String, !sellerID.isEmpty {
                        if (bids[sellerID] ?? 0) < amount {
                            bids[sellerID] = amount
                        }
                    }
                }
                self.highestBids = bids
                self.computeMLRecommendations()
            }
    }

    // MARK: - Highest Bid Helpers
    func highestBid(for seller: SellerLocation) -> Double {
        highestBids[seller.id] ?? 0.0
    }

    func highestBid(for harvest: HarvestLotItem) -> Double {
        highestBids[harvest.id] ?? harvest.currentBid
    }

    // MARK: - Harvests filtered by their own location within the search radius
    var harvestsInRadius: [HarvestLotItem] {
        let centerLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)
        return activeHarvests.filter { harvest in
            let harvestLocation = CLLocation(latitude: harvest.latitude, longitude: harvest.longitude)
            return (harvestLocation.distance(from: centerLocation) / 1000.0) <= searchRadius
        }
    }

    // MARK: - Seller Ratings Listener — keeps sellerID → (avg, count) map live
    private func attachSellerRatingsListener() {
        sellerRatingsListener = Firestore.firestore()
            .collection("users")
            .whereField("role", isEqualTo: "SELLER")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }
                var map: [String: (Double, Int)] = [:]
                for doc in docs {
                    let data = doc.data()
                    let avg   = data["averageRating"] as? Double ?? 0.0
                    let count = data["ratingCount"]   as? Int    ?? 0
                    map[doc.documentID] = (avg, count)
                }
                self.sellerRatings = map
            }
    }

    // MARK: - Live Harvests Listener (all sellers' active harvest and sellers create harvest)
    private func attachHarvestsListener() {
        isLoadingHarvests = true
        harvestsListener = Firestore.firestore()  // firebse harvest lost collection
            .collection("harvestLots")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("Harvests listener error: \(error.localizedDescription)")
                    self.isLoadingHarvests = false
                    return
                }
                self.activeHarvests = snapshot?.documents.compactMap {
                    HarvestLotItem(id: $0.documentID, data: $0.data())
                }.sorted { $0.createdAt > $1.createdAt } ?? []
                self.isLoadingHarvests = false
                self.computeMLRecommendations()
            }
    }

    // MARK: - Notification Permission
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Contracts Listener (tracks historical buyer–seller transaction counts)
    private func attachContractsListener() {
        let buyerID = AuthManager.shared.currentUserID
        guard !buyerID.isEmpty else { return }

        contractsListener = Firestore.firestore()
            .collection("contracts")
            .whereField("buyerID", isEqualTo: buyerID)
            .whereField("status", isEqualTo: "completed")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }
                var counts: [String: Int] = [:]
                for doc in docs {
                    let sellerID = (doc.data()["sellerID"] as? String) ?? ""
                    if !sellerID.isEmpty {
                        counts[sellerID, default: 0] += 1
                    }
                }
                self.historicalTransactions = counts
                self.computeMLRecommendations()
            }
    }

    // Machine learning  Recommendation Scoring
    // Scores registered sellers AND harvest lots, caches top 5 of each.
    func computeMLRecommendations() {
        let engine = RecommendationEngine.shared
        let avgMarketBid = highestBids.values.reduce(0, +) / max(1, Double(highestBids.count))

        // Score registered sellers
        if !allSellers.isEmpty {
            let scoredSellers: [(SellerLocation, Double)] = allSellers.map { seller in
                let sellerVolume    = RecommendationEngine.parseVolume(seller.typicalYield)
                let sellerHasExport = seller.certificationLevel.lowercased().contains("export")
                let sellerBid       = highestBids[seller.id] ?? 0
                let priceDelta      = sellerBid - avgMarketBid
                let txCount         = historicalTransactions[seller.id] ?? 0

                let score = engine.scoreSellerForBuyer(
                    buyerVolume: buyerVolume,
                    sellerVolume: sellerVolume,
                    buyerLocation: searchCenter,
                    sellerLocation: seller.coordinate,
                    buyerNeedsExport: buyerNeedsExport,
                    sellerHasExport: sellerHasExport,
                    priceDelta: priceDelta,
                    historicalTransactions: txCount
                )
                return (seller, score)
            }
            mlRecommendedSellers = scoredSellers
                .sorted { $0.1 > $1.1 }
                .prefix(5)
                .map { $0.0 }
        }

        // register seller create harvest (property) include recommndation system
        if !activeHarvests.isEmpty {
            let scoredHarvests: [(HarvestLotItem, Double)] = activeHarvests.map { harvest in
                let harvestVolume   = harvest.quantity
                let harvestHasExport = harvest.qualityGrade.lowercased().contains("export")
                let harvestLocation  = CLLocationCoordinate2D(latitude: harvest.latitude, longitude: harvest.longitude)
                let harvestBid       = highestBids[harvest.id] ?? harvest.currentBid
                let priceDelta       = harvestBid - avgMarketBid
                // Use seller-level historical transaction count for this harvest's seller
                let txCount          = historicalTransactions[harvest.sellerID] ?? 0

                let score = engine.scoreSellerForBuyer(
                    buyerVolume: buyerVolume,
                    sellerVolume: harvestVolume,
                    buyerLocation: searchCenter,
                    sellerLocation: harvestLocation,
                    buyerNeedsExport: buyerNeedsExport,
                    sellerHasExport: harvestHasExport,
                    priceDelta: priceDelta,
                    historicalTransactions: txCount
                )
                return (harvest, score)
            }
            mlRecommendedHarvests = scoredHarvests
                .sorted { $0.1 > $1.1 }
                .prefix(5)
                .map { $0.0 }
        }
    }

    // Geocode Helper (Resolves a town name to coordinates via MKLocalSearch)
    private func geocode(locationName: String) async -> CLLocationCoordinate2D? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = locationName + ", Sri Lanka"
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718),
            latitudinalMeters: 500_000,
            longitudinalMeters: 500_000
        )
        let search = MKLocalSearch(request: request)
        let response = try? await search.start()
        return response?.mapItems.first?.placemark.coordinate
    }

    // MARK: - Location Search (Moves map center when user types in search bar)
    private func scheduleLocationSearch() {
        searchTask?.cancel()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        searchTask = Task {
            // 0.5s debounce so we don't fire on every keystroke
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }

            isSearchingLocation = true

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            // Bias results toward Sri Lanka
            request.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718),
                latitudinalMeters: 500_000,
                longitudinalMeters: 500_000
            )

            let search = MKLocalSearch(request: request)
            if let response = try? await search.start(),
               let coordinate = response.mapItems.first?.placemark.coordinate {
                searchCenter = coordinate
            }

            isSearchingLocation = false
        }
    }

    
    
    
    var sellersInRadius: [SellerLocation] {
        let centerLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)

        var results = allSellers.filter { seller in
            let sellerLocation = CLLocation(latitude: seller.coordinate.latitude, longitude: seller.coordinate.longitude)
            return (sellerLocation.distance(from: centerLocation) / 1000.0) <= searchRadius
        }

        switch selectedFilter {
        case "High Volume":
            results = results.filter { RecommendationEngine.parseVolume($0.typicalYield) >= 5000 }
        case "Ending Soon":
            results = results.filter { $0.nextHarvestDate.timeIntervalSinceNow < 604800 } // Within 7 days
        case "Nearest to Me":
            results.sort { s1, s2 in
                let loc1 = CLLocation(latitude: s1.coordinate.latitude, longitude: s1.coordinate.longitude)
                let loc2 = CLLocation(latitude: s2.coordinate.latitude, longitude: s2.coordinate.longitude)
                return loc1.distance(from: centerLocation) < loc2.distance(from: centerLocation)
            }
        default:
            break
        }

        return results
    }

    
    var recommendedSellers: [SellerLocation] {
        if !mlRecommendedSellers.isEmpty { return mlRecommendedSellers }
        // Still loading — return empty so ProgressView shows instead of wrong order
        if isLoadingSellers { return [] }
        // Model unavailable fallback — distance sort
        let centerLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)
        return allSellers
            .sorted { s1, s2 in
                let loc1 = CLLocation(latitude: s1.coordinate.latitude, longitude: s1.coordinate.longitude)
                let loc2 = CLLocation(latitude: s2.coordinate.latitude, longitude: s2.coordinate.longitude)
                return loc1.distance(from: centerLocation) < loc2.distance(from: centerLocation)
            }
            .prefix(5)
            .map { $0 }
    }
}
