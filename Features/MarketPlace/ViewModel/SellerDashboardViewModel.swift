import SwiftUI
import MapKit
import FirebaseFirestore

private final class DashboardListenerBox {
    var listener: ListenerRegistration?
    init() {}
    deinit { listener?.remove() }
}

@Observable
@MainActor
class SellerDashboardViewModel {


    var searchText = "" {
        didSet { scheduleLocationSearch() }
    }
    var selectedFilter = "All"
    let filters = ["All", "High Capacity", "Urgent Need", "Nearest to Me"]

    var showProfile = false
    var showNotifications = false
    var unreadNotificationCount: Int = 0


    var profileImageName: String = "Gemini_Generated_Image_bvc5lzbvc5lzbvc5"


    var searchCenter = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609)
    var searchRadius: Double = 50.0
    var isFullScreenMapPresented = false


    var isSearchingLocation = false
    private var searchTask: Task<Void, Never>?


    var allBuyers: [RegisteredBuyer] = []
    var isLoadingBuyers = false

    // Live lowest offer per buyerID — drives the price badge on every buyer card
    var lowestOfferPerBuyer: [String: Double] = [:]
    private let offersListenerBox = DashboardListenerBox()
    private let buyersListenerBox = DashboardListenerBox()
    private let urgentRequestsListenerBox = DashboardListenerBox()

    // Live urgent posts from urgentRequests collection
    var urgentPosts: [UrgentRequest] = []

    // MARK: - Live Dashboard Metrics (replaces hardcoded values)
    var escrowTotal: Double = 0
    var activeOffersTotal: Double = 0
    var urgentContractMessage: String? = nil
    var urgentContract: Contract? = nil
    private let contractListenerBox  = DashboardListenerBox()
    private let disputeListenerBox   = DashboardListenerBox()

    // Internal cache — merged from two separate Firestore listeners
    private var disputeContract:  Contract? = nil
    private var approvedContract: Contract? = nil

    // MARK: - Seller Profile (used by ML engine)
    private var sellerVolume: Int = 5000
    private var sellerHasExport: Bool = false

    // MARK: - Historical Transactions Per Buyer (buyerID → count of completed contracts)
    private var historicalTransactions: [String: Int] = [:]
    private let historyListenerBox = DashboardListenerBox()

    // MARK: - ML-Scored Recommendations Cache
    var mlRecommendedBuyers: [RegisteredBuyer] = []

    init() {
        fetchUserProfile()
        attachBuyersListener()
        attachOffersListener()
        attachUrgentListeners()
        attachUrgentRequestsListener()
        attachContractsHistoryListener()
    }

    // Called from .onAppear so listeners are (re)attached after auth is fully restored
    func onAppear() {
        attachMetricsListener()
        attachUrgentListeners()
    }


    // MARK: - Real-Time Lowest Offer per Buyer
    private func attachOffersListener() {
        offersListenerBox.listener = Firestore.firestore()
            .collection("offers")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Dashboard offers listener error: \(error.localizedDescription)")
                    return
                }

                let allOffers = snapshot?.documents.compactMap {
                    Offer(id: $0.documentID, data: $0.data())
                } ?? []

                // Rebuild the lowest-offer-per-buyer map on every snapshot
                var map: [String: Double] = [:]
                for offer in allOffers {
                    if let existing = map[offer.buyerID] {
                        if offer.amount < existing { map[offer.buyerID] = offer.amount }
                    } else {
                        map[offer.buyerID] = offer.amount
                    }
                }
                self.lowestOfferPerBuyer = map
                self.computeMLRecommendations()

                // activeOffersTotal = sum of the lowest pitch won per buyer by this seller
                let sellerID = AuthManager.shared.currentUserID
                guard !sellerID.isEmpty else { return }
                self.activeOffersTotal = allOffers
                    .filter { $0.sellerID == sellerID }
                    .reduce(0) { $0 + $1.amount }
            }
    }

    // MARK: - Live Urgent Posts listener
    private func attachUrgentRequestsListener() {
        urgentRequestsListenerBox.listener = Firestore.firestore()
            .collection("urgentRequests")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("urgentRequests listener error: \(error.localizedDescription)")
                    return
                }
                self.urgentPosts = snapshot?.documents.compactMap {
                    UrgentRequest(id: $0.documentID, data: $0.data())
                }.sorted { $0.deadline < $1.deadline } ?? []
                print("🔥 urgentPosts loaded: \(self.urgentPosts.count) posts")
            }
    }

    // MARK: - Escrow Total (reuses contractListenerBox — computed from same snapshot)
    private func attachMetricsListener() {
        // escrowTotal is now derived inside attachUrgentListeners from the same snapshot.
        // Nothing to do here — kept for compatibility with onAppear call.
    }

    // MARK: - Urgent listener: single query on sellerID, filter status in Swift (no composite index needed)
    private func attachUrgentListeners() {
        let sellerID = AuthManager.shared.currentUserID
        guard !sellerID.isEmpty else {
            print("⚠️ attachUrgentListeners: currentUserID empty — will retry on onAppear")
            return
        }
        print("✅ attachUrgentListeners: sellerID = \(sellerID)")

        // Remove any existing listeners before re-attaching to avoid duplicates
        contractListenerBox.listener?.remove()
        disputeListenerBox.listener?.remove()

        // Single-field query — no composite index required.
        // We filter by status in Swift so Firestore never needs a multi-field index.
        contractListenerBox.listener = Firestore.firestore()
            .collection("contracts")
            .whereField("sellerID", isEqualTo: sellerID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("Urgent contracts listener error: \(error.localizedDescription)")
                    return
                }
                let allContracts = snapshot?.documents.compactMap {
                    Contract(id: $0.documentID, data: $0.data())
                } ?? []
                print("🟢 contracts snapshot: \(allContracts.count) docs, statuses: \(allContracts.map { $0.status })")

                self.disputeContract  = allContracts.first { $0.status == "dispute" }
                self.approvedContract = allContracts.first { $0.status == "qualityApproved" }
                self.escrowTotal      = allContracts.filter { $0.status == "escrow" }.reduce(0) { $0 + $1.amount }
                self.updateUrgentBanner()
            }
    }

    // Picks the highest-priority contract to show in the banner.
    // Dispute takes priority over quality-approved.
    private func updateUrgentBanner() {
        if let contract = disputeContract {
            urgentContract = contract
            urgentContractMessage = "Buyer raised a dispute on Contract \(contract.contractRef). Review and respond."
            unreadNotificationCount = 1
        } else if let contract = approvedContract {
            urgentContract = contract
            urgentContractMessage = "Buyer approved quality on Contract \(contract.contractRef). Confirm handover to release funds."
            unreadNotificationCount = 1
        } else {
            urgentContract = nil
            urgentContractMessage = nil
            unreadNotificationCount = 0
        }
    }

    // MARK: - Firebase Fetch Logic
    func fetchUserProfile() {
        let userId = AuthManager.shared.currentUserID
        guard !userId.isEmpty else { return }

        Task {
            do {
                let document = try await Firestore.firestore().collection("users").document(userId).getDocument()
                let data = document.data() ?? [:]

                if let imageName = data["profileImageName"] as? String {
                    self.profileImageName = imageName
                }

                // Center map on seller's own estate location
                if let lat = data["latitude"] as? Double,
                   let lng = data["longitude"] as? Double {
                    self.searchCenter = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                }

                // Decode seller profile for ML scoring
                if let yield = data["typicalYield"] as? String {
                    self.sellerVolume = RecommendationEngine.parseVolume(yield)
                }
                let cert = data["certificationLevel"] as? String ?? ""
                self.sellerHasExport = cert.lowercased().contains("export")

                // Re-score now that seller profile is loaded with correct volume
                self.computeMLRecommendations()

            } catch {
                print("Firebase Fetch Error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Live Buyers Listener (real-time so isUrgent changes appear immediately)
    private func attachBuyersListener() {
        isLoadingBuyers = true
        buyersListenerBox.listener = Firestore.firestore()
            .collection("users")
            .whereField("role", isEqualTo: "BUYER")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("Buyers listener error: \(error.localizedDescription)")
                    self.isLoadingBuyers = false
                    return
                }
                Task {
                    var buyers: [RegisteredBuyer] = []
                    for doc in snapshot?.documents ?? [] {
                        let data = doc.data()
                        guard
                            let name     = data["fullName"]     as? String,
                            let location = data["locationName"] as? String
                        else { continue }

                        let volume = data["typicalVolume"] as? String ?? "N/A"
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

                        buyers.append(RegisteredBuyer(
                            id: doc.documentID,
                            name: name,
                            locationName: location,
                            coordinate: coordinate,
                            typicalVolume: volume,
                            businessType: data["businessType"] as? String ?? "",
                            rating: data["averageRating"] as? Double ?? 0.0,
                            ratingCount: data["ratingCount"] as? Int ?? 0,
                            isUrgent: data["isUrgent"] as? Bool ?? false
                        ))
                    }
                    self.allBuyers = buyers
                    self.isLoadingBuyers = false
                    self.computeMLRecommendations()
                }
            }
    }


    // MARK: - Contracts History Listener (tracks per-buyer historical transactions for this seller)
    private func attachContractsHistoryListener() {
        let sellerID = AuthManager.shared.currentUserID
        guard !sellerID.isEmpty else { return }

        historyListenerBox.listener = Firestore.firestore()
            .collection("contracts")
            .whereField("sellerID", isEqualTo: sellerID)
            .whereField("status", isEqualTo: "completed")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }
                var counts: [String: Int] = [:]
                for doc in docs {
                    let buyerID = (doc.data()["buyerID"] as? String) ?? ""
                    if !buyerID.isEmpty {
                        counts[buyerID, default: 0] += 1
                    }
                }
                self.historicalTransactions = counts
                self.computeMLRecommendations()
            }
    }

    // MARK: - ML Recommendation Scoring
    // Scores every registered buyer using the CoreML model and caches top 5.
    func computeMLRecommendations() {
        guard !allBuyers.isEmpty else { return }

        let engine = RecommendationEngine.shared
        let avgMarketOffer = lowestOfferPerBuyer.values.reduce(0, +) / max(1, Double(lowestOfferPerBuyer.count))

        let scored: [(RegisteredBuyer, Double)] = allBuyers.map { buyer in
            let buyerVolume = RecommendationEngine.parseVolume(buyer.typicalVolume)
            let buyerNeedsExport = buyer.businessType.lowercased().contains("export")
            let buyerOffer = lowestOfferPerBuyer[buyer.id] ?? 0
            let priceDelta = buyerOffer - avgMarketOffer
            let txCount = historicalTransactions[buyer.id] ?? 0

            let score = engine.scoreBuyerForSeller(
                sellerVolume: sellerVolume,
                buyerVolume: buyerVolume,
                sellerLocation: searchCenter,
                buyerLocation: buyer.coordinate,
                sellerHasExport: sellerHasExport,
                buyerNeedsExport: buyerNeedsExport,
                priceDelta: priceDelta,
                historicalTransactions: txCount
            )
            return (buyer, score)
        }

        mlRecommendedBuyers = scored
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { $0.0 }
    }

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

    // MARK: - Buyers Within Search Radius (All / High Capacity / Nearest to Me)
    var buyersInRadius: [RegisteredBuyer] {
        let centerLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)

        var results = allBuyers.filter { buyer in
            let buyerLocation = CLLocation(latitude: buyer.coordinate.latitude, longitude: buyer.coordinate.longitude)
            return (buyerLocation.distance(from: centerLocation) / 1000.0) <= searchRadius
        }

        switch selectedFilter {
        case "High Capacity":
            results = results.filter { (Int($0.typicalVolume) ?? 0) >= 10000 }
        case "Nearest to Me":
            results.sort { b1, b2 in
                let loc1 = CLLocation(latitude: b1.coordinate.latitude, longitude: b1.coordinate.longitude)
                let loc2 = CLLocation(latitude: b2.coordinate.latitude, longitude: b2.coordinate.longitude)
                return loc1.distance(from: centerLocation) < loc2.distance(from: centerLocation)
            }
        default:
            break
        }

        return results
    }

    // Build a RegisteredBuyer from an UrgentRequest — uses allBuyers for coordinate if available
    func buyer(for post: UrgentRequest) -> RegisteredBuyer {
        if let match = allBuyers.first(where: { $0.id == post.buyerID }) {
            return match
        }
        // Fallback: build from urgentRequest data with default coordinate
        return RegisteredBuyer(
            id: post.buyerID,
            name: post.buyerName,
            locationName: post.location,
            coordinate: CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718),
            typicalVolume: "\(post.quantity)",
            businessType: "",
            rating: 0.0,
            ratingCount: 0,
            isUrgent: true
        )
    }

    // ML-powered: returns top-5 buyers scored by the CoreML model.
    // Returns empty while loading so UI shows ProgressView, not a flickering distance-sort list.
    var recommendedBuyers: [RegisteredBuyer] {
        if !mlRecommendedBuyers.isEmpty { return mlRecommendedBuyers }
        if isLoadingBuyers { return [] }
        // Model unavailable fallback — distance sort
        let centerLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)
        return allBuyers
            .sorted { b1, b2 in
                let loc1 = CLLocation(latitude: b1.coordinate.latitude, longitude: b1.coordinate.longitude)
                let loc2 = CLLocation(latitude: b2.coordinate.latitude, longitude: b2.coordinate.longitude)
                return loc1.distance(from: centerLocation) < loc2.distance(from: centerLocation)
            }
            .prefix(5)
            .map { $0 }
    }
}

