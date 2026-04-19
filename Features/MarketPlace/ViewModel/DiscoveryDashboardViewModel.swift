
import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

@Observable
@MainActor
class DiscoveryDashboardViewModel {

    // MARK: - UI State
    var searchText = "" {
        didSet { scheduleLocationSearch() }
    }
    var selectedFilter = "All"
    let filters = ["All", "High Volume", "Ending Soon", "Nearest to Me"]

    var showProfile = false
    var showNotifications = false
    var unreadNotificationCount = 3

    // Image State (Defaulting to your asset in case of slow internet)
    var profileImageName: String = "Gemini_Generated_Image_l5uvm3l5uvm3l5uv"

    // MARK: - Map State
    var searchCenter = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609) // Default: Kurunegala
    var searchRadius: Double = 50.0
    var isFullScreenMapPresented = false

    // MARK: - Search State
    var isSearchingLocation = false
    private var searchTask: Task<Void, Never>?

    // MARK: - Sellers Data (Loaded from Firestore)
    var allSellers: [SellerLocation] = []
    var isLoadingSellers = false

    // MARK: - Highest Bids Per Seller (sellerID → highest bid amount)
    var highestBids: [String: Double] = [:]
    private var bidsListener: ListenerRegistration?

    init() {
        fetchUserProfile()
        fetchSellers()
        attachBidsListener()
        requestNotificationPermission()
    }

    // MARK: - Firebase Fetch Logic
    func fetchUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        Task {
            do {
                let document = try await Firestore.firestore().collection("users").document(userId).getDocument()

                // Fetch the asset string we saved during registration
                if let imageName = document.data()?["profileImageName"] as? String {
                    self.profileImageName = imageName
                }
            } catch {
                print("Error fetching profile from Firestore: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Fetch Sellers from Firestore
    func fetchSellers() {
        isLoadingSellers = true

        Task {
            do {
                let snapshot = try await Firestore.firestore()
                    .collection("users")
                    .whereField("role", isEqualTo: "SELLER")
                    .getDocuments()

                var sellers: [SellerLocation] = []

                for doc in snapshot.documents {
                    let data = doc.data()

                    guard
                        let name = data["fullName"] as? String,
                        let location = data["locationName"] as? String
                    else { continue }

                    let yield = data["typicalYield"] as? String ?? "N/A"
                    let cert = data["certificationLevel"] as? String ?? "Standard"
                    let harvestTimestamp = data["nextHarvestDate"] as? Timestamp
                    let harvestDate = harvestTimestamp?.dateValue() ?? Date()

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

                    sellers.append(SellerLocation(
                        id: doc.documentID,
                        sellerName: name,
                        locationName: location,
                        coordinate: coordinate,
                        typicalYield: yield,
                        certificationLevel: cert,
                        nextHarvestDate: harvestDate
                    ))
                }

                self.allSellers = sellers
                self.isLoadingSellers = false

            } catch {
                print("Error fetching sellers from Firestore: \(error.localizedDescription)")
                self.isLoadingSellers = false
            }
        }
    }

    // MARK: - Real-Time Bids Listener (Latest highest bid per seller)
    private func attachBidsListener() {
        bidsListener = Firestore.firestore()
            .collection("bids")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }

                // Group by sellerID and keep the highest amount
                var bids: [String: Double] = [:]
                for doc in docs {
                    let data = doc.data()
                    guard
                        let sellerID = data["sellerID"] as? String,
                        let amount = data["amount"] as? Double
                    else { continue }

                    if (bids[sellerID] ?? 0) < amount {
                        bids[sellerID] = amount
                    }
                }
                self.highestBids = bids
            }
    }

    // MARK: - Highest Bid Helper
    func highestBid(for seller: SellerLocation) -> Double {
        highestBids[seller.id] ?? 0.0
    }

    // MARK: - Notification Permission
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Geocode Helper (Resolves a town name to coordinates via MKLocalSearch)
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

    // MARK: - Filtered Sellers Within Search Radius
    var sellersInRadius: [SellerLocation] {
        let centerLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)

        var results = allSellers.filter { seller in
            let sellerLocation = CLLocation(latitude: seller.coordinate.latitude, longitude: seller.coordinate.longitude)
            return (sellerLocation.distance(from: centerLocation) / 1000.0) <= searchRadius
        }

        switch selectedFilter {
        case "High Volume":
            results = results.filter { (Int($0.typicalYield) ?? 0) >= 5000 }
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

    // MARK: - Recommended Sellers (Top 5 by nearest distance)
    var recommendedSellers: [SellerLocation] {
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
