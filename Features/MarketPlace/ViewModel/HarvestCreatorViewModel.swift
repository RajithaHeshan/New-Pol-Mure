// Location: New-Pol-Mure/Features/MarketPlace/ViewModels/HarvestCreatorViewModel.swift

import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore

@Observable
@MainActor
class HarvestCreatorViewModel {

    // MARK: - User Inputs
    var quantity: String = ""
    var qualityGrade: String = "Premium (Export Quality)"
    var startingPrice: String = ""

    // MARK: - Static Options
    let qualityOptions = [
        "Premium (Export Quality)",
        "Standard (Local Market)",
        "Processing/Oil Grade",
        "Mixed Harvest"
    ]

    // MARK: - Location Data
    var estateLocation = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609)
    var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609),
        latitudinalMeters: 15000,
        longitudinalMeters: 15000
    ))

    // MARK: - Posting State
    var isLaunching  = false
    var launchError: String? = nil
    var launchSuccess = false

    // MARK: - Seller Profile (fetched on init)
    private var currentSellerID:   String = ""
    private var currentSellerName: String = ""
    private var sellerLocationName: String = ""

    init() {
        fetchSellerProfile()
    }

    // MARK: - Fetch Seller Profile
    private func fetchSellerProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        currentSellerID = uid

        Task {
            let doc = try? await Firestore.firestore()
                .collection("users")
                .document(uid)
                .getDocument()
            guard let data = doc?.data() else { return }

            currentSellerName   = data["fullName"]     as? String ?? ""
            sellerLocationName  = data["locationName"] as? String ?? ""

            // Center the privacy map on the seller's own estate
            if let lat = data["latitude"] as? Double,
               let lng = data["longitude"] as? Double {
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                estateLocation = coord
                cameraPosition = .region(MKCoordinateRegion(
                    center: coord,
                    latitudinalMeters: 15000,
                    longitudinalMeters: 15000
                ))
            }
        }
    }

    // MARK: - Logic Engine

    var suggestedPrice: Double {
        switch qualityGrade {
        case "Premium (Export Quality)": return 110.00
        case "Standard (Local Market)":  return 95.00
        case "Processing/Oil Grade":     return 75.00
        default:                         return 85.00
        }
    }

    var marketAverage: Double {
        return suggestedPrice + 5.0
    }

    var isReadyForSuggestion: Bool {
        if quantity.isEmpty { return false }
        if let qty = Int(quantity), qty > 0 { return true }
        return false
    }

    // MARK: - Actions

    func applySuggestion() {
        startingPrice = String(format: "%.2f", suggestedPrice)
    }

    func launchAuction() {
        guard
            let qty = Int(quantity), qty > 0,
            let price = Double(startingPrice), price > 0,
            !currentSellerID.isEmpty
        else { return }

        isLaunching  = true
        launchError  = nil
        launchSuccess = false

        // Auction end date: 7 days from now
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

        let data: [String: Any] = [
            "sellerID":      currentSellerID,
            "sellerName":    currentSellerName,
            "locationName":  sellerLocationName,
            "latitude":      estateLocation.latitude,
            "longitude":     estateLocation.longitude,
            "quantity":      qty,
            "qualityGrade":  qualityGrade,
            "startingPrice": price,
            "currentBid":    price,
            "endDate":       Timestamp(date: endDate),
            "createdAt":     Timestamp()
        ]

        Task {
            do {
                try await Firestore.firestore()
                    .collection("harvestLots")
                    .addDocument(data: data)

                quantity      = ""
                startingPrice = ""
                launchSuccess = true
            } catch {
                print("Launch auction error: \(error.localizedDescription)")
                launchError = error.localizedDescription
            }
            isLaunching = false
        }
    }
}
