
//import SwiftUI
//import MapKit
//import FirebaseAuth
//import FirebaseFirestore
//
//@Observable
//@MainActor
//class SellerDashboardViewModel {
//    // MARK: - UI State
//    var searchText = ""
//    var selectedFilter = "All"
//    let filters = ["All", "High Capacity", "Urgent Need", "Nearest to Me"]
//    
//    var showProfile = false
//    var showNotifications = false
//    var unreadNotificationCount = 2
//    
//    // MARK: - Profile Image State
//    // Restored your custom AI asset name
//    var profileImageName: String = "Gemini_Generated_Image_bvc5lzbvc5lzbvc5"
//    
//    // MARK: - Map State
//    var searchCenter = CLLocationCoordinate2D(latitude: 7.2906, longitude: 80.6337)
//    var searchRadius: Double = 10.0
//    var isFullScreenMapPresented = false
//    
//    init() {
//        fetchUserProfile()
//    }
//    
//    func fetchUserProfile() {
//        guard let userId = Auth.auth().currentUser?.uid else { return }
//        Task {
//            do {
//                let document = try await Firestore.firestore().collection("users").document(userId).getDocument()
//                if let imageName = document.data()?["profileImageName"] as? String {
//                    self.profileImageName = imageName
//                }
//            } catch {
//                print("Firebase Fetch Error: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    // MARK: - Mock Data
//    let recommendedBuyers = [
//        RegisteredBuyer(name: "Heshan Dunumala", locationName: "Warakapola", coordinate: CLLocationCoordinate2D(latitude: 7.2246, longitude: 80.1983), typicalVolume: "10K - 20K Nuts", volumeCapacity: 15000, rating: 4.9, isUrgent: false),
//        RegisteredBuyer(name: "Nimal's Bakery", locationName: "Kaduwela Center", coordinate: CLLocationCoordinate2D(latitude: 6.9333, longitude: 79.9833), typicalVolume: "1K - 5K Nuts", volumeCapacity: 3000, rating: 4.7, isUrgent: true)
//    ]
//    
//    let localBuyers = [
//        RegisteredBuyer(name: "Peradeniya Mills", locationName: "Peradeniya", coordinate: CLLocationCoordinate2D(latitude: 7.2680, longitude: 80.5930), typicalVolume: "5K - 10K Nuts", volumeCapacity: 8000, rating: 4.5, isUrgent: false),
//        RegisteredBuyer(name: "Katugastota Traders", locationName: "Katugastota", coordinate: CLLocationCoordinate2D(latitude: 7.3233, longitude: 80.6214), typicalVolume: "10K+ Nuts", volumeCapacity: 12000, rating: 4.8, isUrgent: false),
//        RegisteredBuyer(name: "Kasun (Event)", locationName: "Kurunegala Zone", coordinate: CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609), typicalVolume: "Under 1K Nuts", volumeCapacity: 500, rating: 4.2, isUrgent: true),
//        RegisteredBuyer(name: "W. Jayasuriya", locationName: "Negombo", coordinate: CLLocationCoordinate2D(latitude: 7.2008, longitude: 79.8737), typicalVolume: "5K - 10K Nuts", volumeCapacity: 8000, rating: 4.5, isUrgent: false)
//    ]
//    
//    var filteredRecommendedBuyers: [RegisteredBuyer] {
//        var results = recommendedBuyers
//        switch selectedFilter {
//        case "High Capacity": results = results.filter { $0.volumeCapacity >= 10000 }
//        case "Urgent Need": results = results.filter { $0.isUrgent == true }
//        default: break
//        }
//        return results
//    }
//    
//    var filteredLocalBuyers: [RegisteredBuyer] {
//        let centerLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)
//        var results = localBuyers.filter { (CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude).distance(from: centerLocation) / 1000.0) <= searchRadius }
//        
//        switch selectedFilter {
//        case "High Capacity": results = results.filter { $0.volumeCapacity >= 10000 }
//        case "Urgent Need": results = results.filter { $0.isUrgent == true }
//        default: break
//        }
//        return results
//    }
//}









import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore

@Observable
@MainActor
class SellerDashboardViewModel {

    // MARK: - UI State
    var searchText = "" {
        didSet { scheduleLocationSearch() }
    }
    var selectedFilter = "All"
    let filters = ["All", "High Capacity", "Urgent Need", "Nearest to Me"]

    var showProfile = false
    var showNotifications = false
    var unreadNotificationCount = 2

    // MARK: - Profile Image State
    var profileImageName: String = "Gemini_Generated_Image_bvc5lzbvc5lzbvc5"

    // MARK: - Map State
    var searchCenter = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609) // Default: Kurunegala
    var searchRadius: Double = 50.0
    var isFullScreenMapPresented = false

    // MARK: - Search State
    var isSearchingLocation = false
    private var searchTask: Task<Void, Never>?

    // MARK: - Buyers Data (Loaded from Firestore)
    var allBuyers: [RegisteredBuyer] = []
    var isLoadingBuyers = false

    init() {
        fetchUserProfile()
        fetchBuyers()
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

    // MARK: - Location Search (Moves map center when seller types in search bar)
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

    // MARK: - Recommended Buyers (Top 5 nearest to seller's estate)
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
