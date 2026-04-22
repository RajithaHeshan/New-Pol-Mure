import SwiftUI
import MapKit
import FirebaseAuth
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

    // MARK: - Live Dashboard Metrics (replaces hardcoded values)
    var escrowTotal: Double = 0
    var activeOffersTotal: Double = 0
    var urgentContractMessage: String? = nil
    var urgentContract: Contract? = nil
    private let metricsListenerBox   = DashboardListenerBox()
    private let contractListenerBox  = DashboardListenerBox()
    private let disputeListenerBox   = DashboardListenerBox()

    // Internal cache — merged from two separate Firestore listeners
    private var disputeContract:  Contract? = nil
    private var approvedContract: Contract? = nil

    init() {
        fetchUserProfile()
        fetchBuyers()
        attachOffersListener()
        attachMetricsListener()
        attachContractListener()
        attachDisputeListener()
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

                // activeOffersTotal = sum of the lowest pitch won per buyer by this seller
                guard let sellerID = Auth.auth().currentUser?.uid else { return }
                self.activeOffersTotal = allOffers
                    .filter { $0.sellerID == sellerID }
                    .reduce(0) { $0 + $1.amount }
            }
    }

    // MARK: - Escrow Total from contracts collection
    private func attachMetricsListener() {
        guard let sellerID = Auth.auth().currentUser?.uid else { return }
        metricsListenerBox.listener = Firestore.firestore()
            .collection("contracts")
            .whereField("sellerID", isEqualTo: sellerID)
            .whereField("status", isEqualTo: "escrow")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("Metrics listener error: \(error.localizedDescription)")
                    return
                }
                self.escrowTotal = snapshot?.documents.reduce(0.0) { sum, doc in
                    sum + ((doc.data()["amount"] as? Double) ?? 0)
                } ?? 0
            }
    }

    // MARK: - Listener: qualityApproved contracts (buyer approved, seller must confirm handover)
    private func attachContractListener() {
        guard let sellerID = Auth.auth().currentUser?.uid else { return }
        contractListenerBox.listener = Firestore.firestore()
            .collection("contracts")
            .whereField("sellerID", isEqualTo: sellerID)
            .whereField("status", isEqualTo: "qualityApproved")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("Contract listener error: \(error.localizedDescription)")
                    return
                }
                self.approvedContract = snapshot?.documents.first.flatMap {
                    Contract(id: $0.documentID, data: $0.data())
                }
                self.updateUrgentBanner()
            }
    }

    // MARK: - Listener: disputed contracts (buyer raised dispute, seller must review)
    private func attachDisputeListener() {
        guard let sellerID = Auth.auth().currentUser?.uid else { return }
        disputeListenerBox.listener = Firestore.firestore()
            .collection("contracts")
            .whereField("sellerID", isEqualTo: sellerID)
            .whereField("status", isEqualTo: "dispute")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("Dispute contract listener error: \(error.localizedDescription)")
                    return
                }
                self.disputeContract = snapshot?.documents.first.flatMap {
                    Contract(id: $0.documentID, data: $0.data())
                }
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
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                let document = try await Firestore.firestore().collection("users").document(userId).getDocument()

                if let imageName = document.data()?["profileImageName"] as? String {
                    self.profileImageName = imageName
                }

                // Center map on seller's own estate location
                if let lat = document.data()?["latitude"] as? Double,
                   let lng = document.data()?["longitude"] as? Double {
                    self.searchCenter = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                }
            } catch {
                print("Firebase Fetch Error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Fetch Buyers from Firestore
    func fetchBuyers() {
        isLoadingBuyers = true

        Task {
            do {
                let snapshot = try await Firestore.firestore()
                    .collection("users")
                    .whereField("role", isEqualTo: "BUYER")
                    .getDocuments()

                var buyers: [RegisteredBuyer] = []

                for doc in snapshot.documents {
                    let data = doc.data()

                    guard
                        let name = data["fullName"] as? String,
                        let location = data["locationName"] as? String
                    else { continue }

                    let volume = data["typicalVolume"] as? String ?? "N/A"

                    // Use stored coordinates if present, otherwise geocode locationName
                    let coordinate: CLLocationCoordinate2D
                    if let lat = data["latitude"] as? Double,
                       let lng = data["longitude"] as? Double {
                        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    } else {
                        // Geocode the locationName and backfill Firestore so this only runs once
                        if let resolved = await geocode(locationName: location) {
                            coordinate = resolved
                            try? await Firestore.firestore()
                                .collection("users")
                                .document(doc.documentID)
                                .updateData(["latitude": resolved.latitude, "longitude": resolved.longitude])
                        } else {
                            continue
                        }
                    }

                    buyers.append(RegisteredBuyer(
                        id: doc.documentID,
                        name: name,
                        locationName: location,
                        coordinate: coordinate,
                        typicalVolume: volume,
                        rating: data["rating"] as? Double ?? 0.0,
                        isUrgent: data["isUrgent"] as? Bool ?? false
                    ))
                }

                self.allBuyers = buyers
                self.isLoadingBuyers = false

            } catch {
                print("Error fetching buyers from Firestore: \(error.localizedDescription)")
                self.isLoadingBuyers = false
            }
        }
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

    // MARK: - Buyers Within Search Radius
    var buyersInRadius: [RegisteredBuyer] {
        let centerLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)

        var results = allBuyers.filter { buyer in
            let buyerLocation = CLLocation(latitude: buyer.coordinate.latitude, longitude: buyer.coordinate.longitude)
            return (buyerLocation.distance(from: centerLocation) / 1000.0) <= searchRadius
        }

        switch selectedFilter {
        case "High Capacity":
            results = results.filter { (Int($0.typicalVolume) ?? 0) >= 10000 }
        case "Urgent Need":
            results = results.filter { $0.isUrgent }
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

  
    var recommendedBuyers: [RegisteredBuyer] {
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

