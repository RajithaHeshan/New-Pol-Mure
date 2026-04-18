

import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore

@Observable
@MainActor
class DiscoveryDashboardViewModel {
    
    // MARK: - UI State
    var searchText = ""
    var selectedFilter = "All"
    let filters = ["All", "High Volume", "Ending Soon", "Nearest to Me"]
    
    var showProfile = false
    var showNotifications = false
    var unreadNotificationCount = 3
    
    // Image State (Defaulting to your asset in case of slow internet)
    var profileImageName: String = "Gemini_Generated_Image_l5uvm3l5uvm3l5uv"
    
    // Map State
    var searchCenter = CLLocationCoordinate2D(latitude: 6.9333, longitude: 79.9833)
    var searchRadius: Double = 5.0
    var isFullScreenMapPresented = false
    
    init() {
        fetchUserProfile()
    }
    
    // MARK: - Firebase Fetch Logic
    func fetchUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                let document = try await Firestore.firestore().collection("users").document(userId).getDocument()
                
                // Fetch the asset string we saved during registration
                if let imageName = document.data()?["profileImageName"] as? String {
                    DispatchQueue.main.async {
                        self.profileImageName = imageName
                    }
                }
            } catch {
                print("Error fetching profile from Firestore: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Mock Data
    let recommendedLots = [
        HarvestLot(sellerInitial: "I. Fernando", locationName: "Kurunegala Zone", coordinate: CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609), quantity: 5000, currentBid: 110.0, endDate: Date().addingTimeInterval(86400)),
        HarvestLot(sellerInitial: "S. Perera", locationName: "Kaduwela Center", coordinate: CLLocationCoordinate2D(latitude: 6.9333, longitude: 79.9833), quantity: 2500, currentBid: 115.0, endDate: Date().addingTimeInterval(172800))
    ]
    
    let generalLots = [
        HarvestLot(sellerInitial: "M. Silva", locationName: "Madampe", coordinate: CLLocationCoordinate2D(latitude: 7.4984, longitude: 79.8441), quantity: 10000, currentBid: 95.0, endDate: Date().addingTimeInterval(259200)),
        HarvestLot(sellerInitial: "K. Alwis", locationName: "Malabe", coordinate: CLLocationCoordinate2D(latitude: 6.9044, longitude: 79.9606), quantity: 800, currentBid: 120.0, endDate: Date().addingTimeInterval(40000)),
        HarvestLot(sellerInitial: "D. Peiris", locationName: "Biyagama", coordinate: CLLocationCoordinate2D(latitude: 6.9428, longitude: 79.9866), quantity: 4500, currentBid: 105.0, endDate: Date().addingTimeInterval(60000)),
        HarvestLot(sellerInitial: "J. Perera", locationName: "Negombo", coordinate: CLLocationCoordinate2D(latitude: 7.2008, longitude: 79.8737), quantity: 6000, currentBid: 130.0, endDate: Date().addingTimeInterval(86400))
    ]
    
    var filteredRecommendedLots: [HarvestLot] {
        var results = recommendedLots
        switch selectedFilter {
        case "High Volume": results = results.filter { $0.quantity >= 5000 }
        case "Ending Soon": results = results.filter { $0.endDate.timeIntervalSinceNow < 172800 }
        case "Nearest to Me":
            let centerLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)
            results.sort { lot1, lot2 in
                let loc1 = CLLocation(latitude: lot1.coordinate.latitude, longitude: lot1.coordinate.longitude)
                let loc2 = CLLocation(latitude: lot2.coordinate.latitude, longitude: lot2.coordinate.longitude)
                return loc1.distance(from: centerLocation) < loc2.distance(from: centerLocation)
            }
        default: break
        }
        return results
    }
    
    var filteredLots: [HarvestLot] {
        let centerLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)
        var results = generalLots.filter { lot in
            let lotLocation = CLLocation(latitude: lot.coordinate.latitude, longitude: lot.coordinate.longitude)
            return (lotLocation.distance(from: centerLocation) / 1000.0) <= searchRadius
        }
        switch selectedFilter {
        case "High Volume": results = results.filter { $0.quantity >= 5000 }
        case "Ending Soon": results = results.filter { $0.endDate.timeIntervalSinceNow < 172800 }
        case "Nearest to Me":
            results.sort { lot1, lot2 in
                let loc1 = CLLocation(latitude: lot1.coordinate.latitude, longitude: lot1.coordinate.longitude)
                let loc2 = CLLocation(latitude: lot2.coordinate.latitude, longitude: lot2.coordinate.longitude)
                return loc1.distance(from: centerLocation) < loc2.distance(from: centerLocation)
            }
        default: break
        }
        return results
    }
}
