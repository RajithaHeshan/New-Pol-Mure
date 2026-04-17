import SwiftUI
import MapKit

@Observable
@MainActor
class SellerDashboardViewModel {
    var searchText = ""
    var selectedFilter = "All"
    let filters = ["All", "High Capacity", "Urgent Need", "Nearest to Me"]
    
    // Global Navigation State
    var showProfile = false
    var showNotifications = false
    var unreadNotificationCount = 2 // Controls the HIG-compliant badge
    
    // Map State
    var searchCenter = CLLocationCoordinate2D(latitude: 7.2906, longitude: 80.6337)
    var searchRadius: Double = 10.0
    var isFullScreenMapPresented = false
    
    // Mock Data
    let recommendedBuyers = [
        RegisteredBuyer(name: "Heshan Dunumala", locationName: "Warakapola", coordinate: CLLocationCoordinate2D(latitude: 7.2246, longitude: 80.1983), typicalVolume: "10K - 20K Nuts", volumeCapacity: 15000, rating: 4.9, isUrgent: false),
        RegisteredBuyer(name: "Nimal's Bakery", locationName: "Kaduwela Center", coordinate: CLLocationCoordinate2D(latitude: 6.9333, longitude: 79.9833), typicalVolume: "1K - 5K Nuts", volumeCapacity: 3000, rating: 4.7, isUrgent: true)
    ]
    
    let localBuyers = [
        RegisteredBuyer(name: "Peradeniya Mills", locationName: "Peradeniya", coordinate: CLLocationCoordinate2D(latitude: 7.2680, longitude: 80.5930), typicalVolume: "5K - 10K Nuts", volumeCapacity: 8000, rating: 4.5, isUrgent: false),
        RegisteredBuyer(name: "Katugastota Traders", locationName: "Katugastota", coordinate: CLLocationCoordinate2D(latitude: 7.3233, longitude: 80.6214), typicalVolume: "10K+ Nuts", volumeCapacity: 12000, rating: 4.8, isUrgent: false),
        RegisteredBuyer(name: "Kasun (Event)", locationName: "Kurunegala Zone", coordinate: CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609), typicalVolume: "Under 1K Nuts", volumeCapacity: 500, rating: 4.2, isUrgent: true),
        RegisteredBuyer(name: "W. Jayasuriya", locationName: "Negombo", coordinate: CLLocationCoordinate2D(latitude: 7.2008, longitude: 79.8737), typicalVolume: "5K - 10K Nuts", volumeCapacity: 8000, rating: 4.5, isUrgent: false)
    ]
    
    // Computed Properties for Filtering
    var filteredRecommendedBuyers: [RegisteredBuyer] {
        var results = recommendedBuyers
        switch selectedFilter {
        case "High Capacity": results = results.filter { $0.volumeCapacity >= 10000 }
        case "Urgent Need": results = results.filter { $0.isUrgent == true }
        case "Nearest to Me":
            let centerLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)
            results.sort { b1, b2 in
                let loc1 = CLLocation(latitude: b1.coordinate.latitude, longitude: b1.coordinate.longitude)
                let loc2 = CLLocation(latitude: b2.coordinate.latitude, longitude: b2.coordinate.longitude)
                return loc1.distance(from: centerLocation) < loc2.distance(from: centerLocation)
            }
        default: break
        }
        return results
    }
    
    var filteredLocalBuyers: [RegisteredBuyer] {
        let centerLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)
        
        var results = localBuyers.filter { buyer in
            let buyerLocation = CLLocation(latitude: buyer.coordinate.latitude, longitude: buyer.coordinate.longitude)
            return (buyerLocation.distance(from: centerLocation) / 1000.0) <= searchRadius
        }
        
        switch selectedFilter {
        case "High Capacity": results = results.filter { $0.volumeCapacity >= 10000 }
        case "Urgent Need": results = results.filter { $0.isUrgent == true }
        case "Nearest to Me":
            results.sort { b1, b2 in
                let loc1 = CLLocation(latitude: b1.coordinate.latitude, longitude: b1.coordinate.longitude)
                let loc2 = CLLocation(latitude: b2.coordinate.latitude, longitude: b2.coordinate.longitude)
                return loc1.distance(from: centerLocation) < loc2.distance(from: centerLocation)
            }
        default: break
        }
        return results
    }
}

