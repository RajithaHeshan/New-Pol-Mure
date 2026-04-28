import SwiftUI
import MapKit
import FirebaseFirestore

@Observable
@MainActor
class ProfileViewModel {

    // MARK: - Display / Read-only
    var profileImageName: String = ""
    var role: String = ""
    var email: String = ""

    // MARK: - Editable — common
    var fullName: String = ""
    var phone: String = ""
    var locationName: String = ""
    var coordinate = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609)

    // MARK: - Editable — seller only
    var typicalYield: String = ""
    var certificationLevel: String = ""
    var nextHarvestDate: Date = Date()
    let certificationLevels = ["Standard (Local Market)", "Export Quality", "Organic Certified", "GAP Certified"]

    // MARK: - Editable — buyer only
    var typicalVolume: String = ""
    var businessType: String = ""
    let businessTypes = ["Retailer / Grocery", "Bakery / Restaurant", "Oil Processing Facility",
                         "Desiccated Coconut Plant", "Exporter", "Event Planner", "Other"]

    // MARK: - State
    var isLoading = false
    var isSaving = false
    var saveSuccess = false
    var errorMessage: String? = nil
    var isMapPresented = false

    var isSeller: Bool { role == "SELLER" }

    // MARK: - Load Profile
    func load() {
        let uid = AuthManager.shared.currentUserID
        guard !uid.isEmpty else { return }
        isLoading = true

        Task {
            do {
                let doc = try await Firestore.firestore().collection("users").document(uid).getDocument()
                let d = doc.data() ?? [:]

                profileImageName = d["profileImageName"] as? String ?? ""
                role             = d["role"]            as? String ?? ""
                email            = d["email"]           as? String ?? ""
                fullName         = d["fullName"]        as? String ?? ""
                phone            = d["phone"]           as? String ?? ""
                locationName     = d["locationName"]    as? String ?? ""

                if let lat = d["latitude"] as? Double,
                   let lng = d["longitude"] as? Double {
                    coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                }

                // Seller-specific
                typicalYield       = d["typicalYield"]       as? String ?? ""
                certificationLevel = d["certificationLevel"] as? String ?? certificationLevels[0]
                if let ts = d["nextHarvestDate"] as? Timestamp {
                    nextHarvestDate = ts.dateValue()
                }

                // Buyer-specific
                typicalVolume = d["typicalVolume"] as? String ?? ""
                businessType  = d["businessType"]  as? String ?? businessTypes[0]

                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    // MARK: - Save Profile
    func save() {
        let uid = AuthManager.shared.currentUserID
        guard !uid.isEmpty else { return }
        isSaving = true
        errorMessage = nil

        var update: [String: Any] = [
            "fullName":     fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            "phone":        phone.trimmingCharacters(in: .whitespacesAndNewlines),
            "locationName": locationName,
            "latitude":     coordinate.latitude,
            "longitude":    coordinate.longitude
        ]

        if isSeller {
            update["typicalYield"]       = typicalYield.trimmingCharacters(in: .whitespacesAndNewlines)
            update["certificationLevel"] = certificationLevel
            update["nextHarvestDate"]    = Timestamp(date: nextHarvestDate)
        } else {
            update["typicalVolume"] = typicalVolume.trimmingCharacters(in: .whitespacesAndNewlines)
            update["businessType"]  = businessType
        }

        Task {
            do {
                try await Firestore.firestore().collection("users").document(uid).updateData(update)
                isSaving = false
                saveSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }

    // MARK: - Sign Out
    func signOut() {
        AuthManager.shared.signOut()
    }
}
