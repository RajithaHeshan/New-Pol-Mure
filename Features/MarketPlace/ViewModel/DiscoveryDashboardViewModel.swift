
import SwiftUI
import MapKit
import FirebaseFirestore
import UserNotifications
import CoreLocation

@Observable
@MainActor
class DiscoveryDashboardViewModel: NSObject, CLLocationManagerDelegate {

   
    private let locationManager = CLLocationManager()
    var deviceLocation: CLLocationCoordinate2D? = nil

    var searchText = "" {
        didSet { scheduleLocationSearch() } 
    }
  
    var selectedFilter = "All"
    let filters = ["All", "High Volume", "Ending Soon"]

    var showProfile = false
    var showNotifications = false
    var unreadNotificationCount: Int { NotificationStore.shared.unreadCount(ownerID: currentUserID) }
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

  
    var highestBids: [String: Double] = [:]
    private var bidsListener: ListenerRegistration?

    
     //when buyer placed bid for seller and when accept it locked

    var lockedSellerIDs:  Set<String> = []
    var lockedHarvestIDs: Set<String> = []
    private var activeContractSellerIDs:    Set<String> = []
    private var activeContractHarvestIDs:   Set<String> = []
    private var completedContractSellerIDs: Set<String> = []
    private var completedContractHarvestIDs: Set<String> = []
    private var acceptedBidSellerIDs:       Set<String> = []
    private var acceptedBidHarvestIDs:      Set<String> = []
    private var myBidsListener: ListenerRegistration?

    
    //after contract renew
    
    private func recomputeLocks() {
        let completedSellers = completedContractSellerIDs.union(completedContractHarvestIDs)
        let activeBidSellerLocks  = acceptedBidSellerIDs.subtracting(completedSellers)
        let activeBidHarvestLocks = acceptedBidHarvestIDs.subtracting(completedContractHarvestIDs)
        lockedSellerIDs  = activeContractSellerIDs.union(activeBidSellerLocks)
        lockedHarvestIDs = activeContractHarvestIDs.union(activeBidHarvestLocks)
    }

   
    var activeHarvests: [HarvestLotItem] = []
    var isLoadingHarvests = false
    private var harvestsListener: ListenerRegistration?

  
    var sellerRatings: [String: (Double, Int)] = [:]
    private var sellerRatingsListener: ListenerRegistration?

   
    private var buyerVolume: Int = 5000
    private var buyerNeedsExport: Bool = false
   
    private var buyerCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609)

   
    private var historicalTransactions: [String: Int] = [:]
    private var contractsListener: ListenerRegistration?

 
    var mlRecommendedSellers: [SellerLocation] = []
    var mlRecommendedHarvests: [HarvestLotItem] = []



    override init() {
        super.init()
        setupLocationManager()
        fetchUserProfile()
        attachSellersListener()
        attachBidsListener()
        attachMyBidsListener()
        attachHarvestsListener()
        attachSellerRatingsListener()
        attachContractsListener()
        attachMonthlySpendListener()
        requestNotificationPermission()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            self.deviceLocation = latest.coordinate
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
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
                    let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    self.searchCenter    = coord
                    self.buyerCoordinate = coord  // fixed reference for ML scoring — never moves with search
                }

                self.computeMLRecommendations()
            } catch {
                print("Error fetching profile from Firestore: \(error.localizedDescription)")
            }
        }
    }

    
    func attachMonthlySpendListener(retryCount: Int = 0) {
        let buyerID = AuthManager.shared.currentUserID
        if buyerID.isEmpty {
            guard retryCount < 5 else { return }
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                attachMonthlySpendListener(retryCount: retryCount + 1)
            }
            return
        }

        
        monthlySpendListener?.remove()

        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        monthlySpendListener = Firestore.firestore()
            .collection("transactions")
            .whereField("buyerID", isEqualTo: buyerID)
            .whereField("isCredit", isEqualTo: false)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }
                self.monthlySpend = docs
                    .filter {
                        let completedAt = ($0.data()["completedAt"] as? Timestamp)?.dateValue() ?? .distantPast
                        return completedAt >= monthStart
                    }
                    .compactMap { $0.data()["amount"] as? Double }
                    .reduce(0, +)
            }
    }

   
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


    
    private func attachBidsListener() {
        bidsListener = Firestore.firestore()
            .collection("bids")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }

                var bids: [String: Double] = [:]
                for doc in docs {
                    let data = doc.data()
                    guard let amount = data["amount"] as? Double else { continue }


                    if let harvestID = data["harvestID"] as? String, !harvestID.isEmpty {
                        if (bids[harvestID] ?? 0) < amount {
                            bids[harvestID] = amount
                        }
                    }

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

   
   
    private func attachMyBidsListener() {
        myBidsListener = Firestore.firestore()
            .collection("bids")
            .whereField("wasAccepted", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }

                var sellerLocks:  Set<String> = []
                var harvestLocks: Set<String> = []

                for doc in docs {
                    let data      = doc.data()
                    let harvestID = data["harvestID"] as? String ?? ""
                    if !harvestID.isEmpty {
                        // Bid on a harvest lot — gray 
                        harvestLocks.insert(harvestID)
                    } else {
                        // Bid on a registered seller directly — gray the seller card
                        if let sellerID = data["sellerID"] as? String, !sellerID.isEmpty {
                            sellerLocks.insert(sellerID)
                        }
                    }
                }

                self.acceptedBidSellerIDs  = sellerLocks
                self.acceptedBidHarvestIDs = harvestLocks
                self.recomputeLocks()
            }
    }

    func highestBid(for seller: SellerLocation) -> Double {
        highestBids[seller.id] ?? 0.0
    }

    func highestBid(for harvest: HarvestLotItem) -> Double {
        highestBids[harvest.id] ?? harvest.currentBid
    }

   

    var harvestsInRadius: [HarvestLotItem] {
        let centerLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)
        let gpsLocation = deviceLocation.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
        let radiusCenter = (selectedFilter == "Nearest to Me" ? gpsLocation : nil) ?? centerLocation

        var results = activeHarvests.filter { harvest in
            let harvestLocation = CLLocation(latitude: harvest.latitude, longitude: harvest.longitude)
            return (harvestLocation.distance(from: radiusCenter) / 1000.0) <= searchRadius
        }

        switch selectedFilter {
        case "High Volume":
            results = results.filter { $0.quantity >= 5000 }
        case "Ending Soon":
            results = results.filter { $0.endDate.timeIntervalSinceNow < 172800 && $0.endDate > Date() }
        case "Nearest to Me":
            results.sort { h1, h2 in
                let loc1 = CLLocation(latitude: h1.latitude, longitude: h1.longitude)
                let loc2 = CLLocation(latitude: h2.latitude, longitude: h2.longitude)
                return loc1.distance(from: radiusCenter) < loc2.distance(from: radiusCenter)
            }
        default:
            break
        }

        return results
    }

   
    private func attachSellerRatingsListener() {
        sellerRatingsListener = Firestore.firestore()
            .collection("users")
            .whereField("role", isEqualTo: "SELLER")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }
                var map: [String: (Double, Int)] = [:]
                for doc in docs {
                    let data  = doc.data()
                    let avg   = data["averageRating"] as? Double ?? 0.0
                    let count = data["ratingCount"]   as? Int    ?? 0
                    map[doc.documentID] = (avg, count)
                }
                self.sellerRatings = map

                // Propagate fresh ratings into allSellers so ML scores reflect latest ratings
                self.allSellers = self.allSellers.map { seller in
                    guard let updated = map[seller.id] else { return seller }
                    return SellerLocation(
                        id:                 seller.id,
                        sellerName:         seller.sellerName,
                        locationName:       seller.locationName,
                        coordinate:         seller.coordinate,
                        typicalYield:       seller.typicalYield,
                        certificationLevel: seller.certificationLevel,
                        nextHarvestDate:    seller.nextHarvestDate,
                        averageRating:      updated.0,
                        ratingCount:        updated.1
                    )
                }
                self.computeMLRecommendations()
            }
    }

    
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

   
    private func attachContractsListener(retryCount: Int = 0) {
        let buyerID = AuthManager.shared.currentUserID
        if buyerID.isEmpty {
            guard retryCount < 5 else { return }
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                attachContractsListener(retryCount: retryCount + 1)
            }
            return
        }

        contractsListener?.remove()

        // Global listener — locks sellers/harvests that have ANY active contract from ANY buyer
        contractsListener = Firestore.firestore()
            .collection("contracts")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }

                var counts:             [String: Int] = [:]
                var activeSellerIDs:    Set<String>   = []
                var activeHarvestIDs:   Set<String>   = []
                var completedSellerIDs: Set<String>   = []
                var completedHarvestIDs: Set<String>  = []

                for doc in docs {
                    let data            = doc.data()
                    let sellerID        = data["sellerID"] as? String ?? ""
                    let contractBuyerID = data["buyerID"]  as? String ?? ""
                    let status          = data["status"]   as? String ?? ""
                    guard !sellerID.isEmpty else { continue }

                    let source = data["source"] as? String ?? ""
                    let isDone = status == "completed" || status == "rejected"

                    // ML scoring: count only this buyer's completed contracts
                    if status == "completed", contractBuyerID == buyerID {
                        counts[sellerID, default: 0] += 1
                    }

                    // Only bid-based contracts lock on buyer dashboard
                    guard source == "bid" else { continue }

                    let harvestID = data["harvestID"] as? String ?? ""

                    if isDone {
                        if !harvestID.isEmpty {
                            completedHarvestIDs.insert(harvestID)
                        } else {
                            completedSellerIDs.insert(sellerID)
                        }
                    } else {
                        if !harvestID.isEmpty {
                            // Bid on harvest — gray only harvest
                            activeHarvestIDs.insert(harvestID)
                        } else {
                            // Bid on registered seller — gray seller
                            activeSellerIDs.insert(sellerID)
                        }
                    }
                }

                self.historicalTransactions     = counts
                self.activeContractSellerIDs    = activeSellerIDs
                self.activeContractHarvestIDs   = activeHarvestIDs
                self.completedContractSellerIDs  = completedSellerIDs
                self.completedContractHarvestIDs = completedHarvestIDs
                self.recomputeLocks()
                self.computeMLRecommendations()
            }
    }

    
    func computeMLRecommendations() {
        let engine = RecommendationEngine.shared
        let avgMarketBid = highestBids.values.reduce(0, +) / max(1, Double(highestBids.count))

        // Score registered sellers
        if !allSellers.isEmpty {
            let scoredSellers: [(SellerLocation, Double)] = allSellers.map { seller in
                let sellerVolume    = RecommendationEngine.parseVolume(seller.typicalYield)
                let sellerHasExport = seller.certificationLevel.lowercased().contains("export")
                let sellerBid       = highestBids[seller.id] ?? 0 //current higihet Bid
                let priceDelta      = sellerBid - avgMarketBid  //kamla bid vs market average
                let txCount         = historicalTransactions[seller.id] ?? 0

                let score = engine.scoreSellerForBuyer(
                    buyerVolume: buyerVolume,
                    sellerVolume: sellerVolume,
                    buyerLocation: buyerCoordinate,
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
                    buyerLocation: buyerCoordinate,
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




   //location search
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
        let gpsLocation = deviceLocation.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
        let radiusCenter = (selectedFilter == "Nearest to Me" ? gpsLocation : nil) ?? centerLocation

        var results = allSellers.filter { seller in
            let sellerLocation = CLLocation(latitude: seller.coordinate.latitude, longitude: seller.coordinate.longitude)
            return (sellerLocation.distance(from: radiusCenter) / 1000.0) <= searchRadius
        }

        switch selectedFilter {
        case "High Volume":
            results = results.filter { RecommendationEngine.parseVolume($0.typicalYield) >= 5000 }
        case "Ending Soon":
            results = results.filter {
                let t = $0.nextHarvestDate.timeIntervalSinceNow
                return t > 0 && t < 172800
            }
        case "Nearest to Me":
            results.sort { s1, s2 in
                let loc1 = CLLocation(latitude: s1.coordinate.latitude, longitude: s1.coordinate.longitude)
                let loc2 = CLLocation(latitude: s2.coordinate.latitude, longitude: s2.coordinate.longitude)
                return loc1.distance(from: radiusCenter) < loc2.distance(from: radiusCenter)
            }
        default:
            break
        }

        return results
    }

    
    var recommendedSellers: [SellerLocation] {
        if !mlRecommendedSellers.isEmpty { return mlRecommendedSellers }
      
        if isLoadingSellers { return [] }
       
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
