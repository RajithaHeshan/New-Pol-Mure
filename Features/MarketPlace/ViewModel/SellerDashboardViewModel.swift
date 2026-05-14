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
    let filters = ["All", "High Capacity", "Urgent Need"]

    var showProfile = false
    var showNotifications = false
    var unreadNotificationCount: Int = 0
    var currentUserID: String { AuthManager.shared.currentUserID }


    var profileImageName: String = "Gemini_Generated_Image_bvc5lzbvc5lzbvc5"
    var fullName: String = ""


    var searchCenter = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609)
    // Seller's own registered estate coordinate — fixed for ML scoring, never moves with search
    private var sellerCoordinate = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609)
    var searchRadius: Double = 50.0
    var isFullScreenMapPresented = false


    var isSearchingLocation = false
    private var searchTask: Task<Void, Never>?


    var allBuyers: [RegisteredBuyer] = []
    var isLoadingBuyers = false


    var highestOfferPerBuyer: [String: Double] = [:]
    var highestUrgentPitchPerBuyer: [String: Double] = [:]
    private let offersListenerBox = DashboardListenerBox()
    private let buyersListenerBox = DashboardListenerBox()
    private let urgentRequestsListenerBox = DashboardListenerBox()

   
    var urgentPosts: [UrgentRequest] = []

   
    var escrowTotal: Double = 0
    var activeOffersTotal: Double = 0
    var urgentContractMessage: String? = nil
    var urgentContract: Contract? = nil
    private let contractListenerBox  = DashboardListenerBox()
    private let disputeListenerBox   = DashboardListenerBox()

   
    private var disputeContract:  Contract? = nil
    private var approvedContract: Contract? = nil

   
    var disputeReason: String? = nil
    var disputeNotes: String? = nil
    var disputeCounterOffer: Double? = nil

   
    private var sellerVolume: Int = 5000
    private var sellerHasExport: Bool = false

   
    private var historicalTransactions: [String: Int] = [:]
    private let historyListenerBox = DashboardListenerBox()

 
    var mlRecommendedBuyers: [RegisteredBuyer] = []

    // MARK: - Pitch lock state for buyer cards on seller dashboard
    // When a buyer accepts a pitch → gray that buyer's card for ALL sellers until contract completes.
    var lockedBuyerIDs: Set<String> = []
    private var acceptedOfferBuyerIDs:     Set<String> = []
    private var activeContractBuyerIDs:    Set<String> = []
    private var completedContractBuyerIDs: Set<String> = []
    private let acceptedOffersListenerBox  = DashboardListenerBox()
    private let globalContractsListenerBox = DashboardListenerBox()

    private func recomputeLocks() {
        let activePitchLocks = acceptedOfferBuyerIDs.subtracting(completedContractBuyerIDs)
        lockedBuyerIDs = activeContractBuyerIDs.union(activePitchLocks)
    }

    init() {
        fetchUserProfile()
        attachBuyersListener()
        attachOffersListener()
        attachAcceptedOffersListener()
        attachGlobalContractsListener()
        attachUrgentListeners()
        attachUrgentRequestsListener()
        attachContractsHistoryListener()
    }

    
    func onAppear() {
        fetchUserProfile()
        attachMetricsListener()
        attachUrgentListeners()
    }


   
    private func attachOffersListener() {
        offersListenerBox.listener = Firestore.firestore()
            .collection("offers")
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Dashboard offers listener error: \(error.localizedDescription)")
                    return
                }

                let allOffers = snapshot?.documents.compactMap {
                    Offer(id: $0.documentID, data: $0.data())
                } ?? []

                // Rebuild separate highest-pitch maps for normal and urgent offers
                var normalMap: [String: Double] = [:]
                var urgentMap: [String: Double] = [:]
                for offer in allOffers {
                    if offer.isUrgentPitch {
                        if (urgentMap[offer.buyerID] ?? 0) < offer.amount {
                            urgentMap[offer.buyerID] = offer.amount
                        }
                    } else {
                        if (normalMap[offer.buyerID] ?? 0) < offer.amount {
                            normalMap[offer.buyerID] = offer.amount
                        }
                    }
                }
                self.highestOfferPerBuyer = normalMap
                self.highestUrgentPitchPerBuyer = urgentMap
                self.computeMLRecommendations()

                // activeOffersTotal = sum of this seller's active pitches
                let sellerID = AuthManager.shared.currentUserID
                guard !sellerID.isEmpty else { return }
                self.activeOffersTotal = allOffers
                    .filter { $0.sellerID == sellerID }
                    .reduce(0) { $0 + $1.amount }
            }
    }

    private func attachAcceptedOffersListener() {
        acceptedOffersListenerBox.listener = Firestore.firestore()
            .collection("offers")
            .whereField("wasAccepted", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }
                var buyerLocks: Set<String> = []
                for doc in docs {
                    let data = doc.data()
                    if let buyerID = data["buyerID"] as? String, !buyerID.isEmpty {
                        buyerLocks.insert(buyerID)
                    }
                }
                self.acceptedOfferBuyerIDs = buyerLocks
                self.recomputeLocks()
            }
    }

    private func attachGlobalContractsListener() {
        globalContractsListenerBox.listener = Firestore.firestore()
            .collection("contracts")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }

                var activeBuyerIDs:    Set<String> = []
                var completedBuyerIDs: Set<String> = []

                for doc in docs {
                    let data    = doc.data()
                    let buyerID = data["buyerID"] as? String ?? ""
                    let status  = data["status"]  as? String ?? ""
                    let source  = data["source"]  as? String ?? ""
                    guard !buyerID.isEmpty else { continue }
                    // Only pitch-based contracts lock buyer cards on seller dashboard
                    guard source == "offer" else { continue }

                    let isDone = status == "completed" || status == "rejected"
                    if isDone {
                        completedBuyerIDs.insert(buyerID)
                    } else {
                        activeBuyerIDs.insert(buyerID)
                    }
                }

                self.activeContractBuyerIDs    = activeBuyerIDs
                self.completedContractBuyerIDs = completedBuyerIDs
                self.recomputeLocks()
            }
    }

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

    
    private func attachMetricsListener() {
        
    }

   //related uirgent post according to seller id 
   
    private func attachUrgentListeners() {
        let sellerID = AuthManager.shared.currentUserID
        guard !sellerID.isEmpty else {
            print("⚠️ attachUrgentListeners: currentUserID empty — will retry on onAppear")
            return
        }
        print("✅ attachUrgentListeners: sellerID = \(sellerID)")

       
        contractListenerBox.listener?.remove()
        disputeListenerBox.listener?.remove()

        
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


//urgent banner  

    private func updateUrgentBanner() {
        if let contract = disputeContract {
            urgentContract = contract
            urgentContractMessage = "Buyer raised a dispute on Contract \(contract.contractRef). Fetching details..."
            unreadNotificationCount = 1
            fetchDisputeDetails(for: contract.id)
        } else if let contract = approvedContract {
            urgentContract = contract
            urgentContractMessage = "Buyer approved quality on Contract \(contract.contractRef). Confirm handover to release funds."
            disputeReason = nil
            disputeNotes = nil
            disputeCounterOffer = nil
            unreadNotificationCount = 1
        } else {
            urgentContract = nil
            urgentContractMessage = nil
            disputeReason = nil
            disputeNotes = nil
            disputeCounterOffer = nil
            unreadNotificationCount = 0
        }
    }

    private func fetchDisputeDetails(for contractID: String) {
        Task {
            do {
                // No order(by:) — avoids composite index requirement
                let snapshot = try await Firestore.firestore()
                    .collection("disputes")
                    .whereField("contractID", isEqualTo: contractID)
                    .whereField("status", isEqualTo: "pending")
                    .getDocuments()

                // Pick the most recent by sorting in Swift
                let doc = snapshot.documents.max {
                    let a = ($0.data()["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
                    let b = ($1.data()["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
                    return a < b
                }
                guard let doc else {
                    if let contract = self.disputeContract {
                        self.urgentContractMessage = "Buyer raised a dispute on Contract \(contract.contractRef). Review and respond."
                    }
                    return
                }
                let data = doc.data()

                let reason  = data["reason"] as? String ?? ""
                let notes   = data["notes"]  as? String ?? ""
                let counter = data["counterOfferAmount"] as? Double ?? 0

                self.disputeReason       = reason.isEmpty ? nil : reason
                self.disputeNotes        = notes.isEmpty  ? nil : notes
                self.disputeCounterOffer = counter > 0    ? counter : nil

                if let contract = self.disputeContract {
                    var msg = "Dispute on Contract \(contract.contractRef)"
                    if !reason.isEmpty { msg += ": \(reason)" }
                    if !notes.isEmpty  { msg += " — \(notes)" }
                    if counter > 0     { msg += ". Counter-offer: Rs \(Int(counter))" }
                    self.urgentContractMessage = msg
                }
            } catch {
                if let contract = self.disputeContract {
                    self.urgentContractMessage = "Buyer raised a dispute on Contract \(contract.contractRef). Review and respond."
                }
            }
        }
    }



   
    func fetchUserProfile(retryCount: Int = 0) {
        let userId = AuthManager.shared.currentUserID

        if userId.isEmpty {
            guard retryCount < 5 else { return }
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                fetchUserProfile(retryCount: retryCount + 1)
            }
            return
        }

        Task {
            do {
                let document = try await Firestore.firestore().collection("users").document(userId).getDocument()
                let data = document.data() ?? [:]

                if let imageName = data["profileImageName"] as? String {
                    self.profileImageName = imageName
                }
                if let name = data["fullName"] as? String {
                    self.fullName = name
                }

                // Center map on seller's own estate location
                if let lat = data["latitude"] as? Double,
                   let lng = data["longitude"] as? Double {
                    let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    self.searchCenter    = coord
                    self.sellerCoordinate = coord  // fixed reference for ML scoring — never moves with search
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


    
    private func attachContractsHistoryListener(retryCount: Int = 0) {
        let sellerID = AuthManager.shared.currentUserID
        if sellerID.isEmpty {
            guard retryCount < 5 else { return }
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                attachContractsHistoryListener(retryCount: retryCount + 1)
            }
            return
        }

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

    
    func computeMLRecommendations() {
        guard !allBuyers.isEmpty else { return }

        let engine = RecommendationEngine.shared
        let avgMarketOffer = highestOfferPerBuyer.values.reduce(0, +) / max(1, Double(highestOfferPerBuyer.count))

        let scored: [(RegisteredBuyer, Double)] = allBuyers.map { buyer in
            let buyerVolume = RecommendationEngine.parseVolume(buyer.typicalVolume)
            let buyerNeedsExport = buyer.businessType.lowercased().contains("export")
            let buyerOffer = highestOfferPerBuyer[buyer.id] ?? 0
            let priceDelta = buyerOffer - avgMarketOffer
            let txCount = historicalTransactions[buyer.id] ?? 0

            let score = engine.scoreBuyerForSeller(
                sellerVolume: sellerVolume,
                buyerVolume: buyerVolume,
                sellerLocation: sellerCoordinate,
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

    
    var buyersInRadius: [RegisteredBuyer] {
        let centerLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)

        var results = allBuyers.filter { buyer in
            let buyerLocation = CLLocation(latitude: buyer.coordinate.latitude, longitude: buyer.coordinate.longitude)
            return (buyerLocation.distance(from: centerLocation) / 1000.0) <= searchRadius
        }

        switch selectedFilter {
        case "High Capacity":
            results = results.filter { RecommendationEngine.parseVolume($0.typicalVolume) >= 5000 }
        case "Urgent Need":
            let urgentBuyerIDs = Set(urgentPosts.map { $0.buyerID })
            results = results.filter { urgentBuyerIDs.contains($0.id) }
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

   
    //top five buyers according to Ml
    
    var recommendedBuyers: [RegisteredBuyer] {
        if !mlRecommendedBuyers.isEmpty { return mlRecommendedBuyers }
        if isLoadingBuyers { return [] }
        
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

