

import SwiftUI
import MapKit

@Observable
@MainActor
class BuyerRegistrationViewModel {
    // MARK: - Account Details
    var fullName = ""
    var email = ""
    var phone = ""
    var password = ""
    
    // MARK: - Business Profile
    var businessType = "Retailer / Grocery"
    var customBusinessType = ""
    var typicalVolume = ""
    var volumeUnit = "Nuts"
    
    // MARK: - Map State
    var buyerLocation = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609)
    var locationName = "Kurunegala"
    var isFullScreenMapPresented = false
    
    // MARK: - Constants for Pickers
    let businessTypes = [
        "Retailer / Grocery",
        "Bakery / Restaurant",
        "Oil Processing Facility",
        "Desiccated Coconut Plant",
        "Exporter",
        "Event Planner",
        "Other"
    ]
    let volumeUnits = ["Nuts", "kg"]
    
    // MARK: - Validation Logic
    var isFormValid: Bool {
        let isBaseValid = !fullName.isEmpty &&
                          !email.isEmpty && email.contains("@") &&
                          !phone.isEmpty &&
                          !password.isEmpty && password.count >= 6 &&
                          !typicalVolume.isEmpty
        
        if businessType == "Other" {
            return isBaseValid && !customBusinessType.isEmpty
        }
        return isBaseValid
    }
    
    // MARK: - Registration Trigger
    func registerBuyer(onSuccess: @escaping () -> Void) {
        Task {
            do {
                // Pass standard text data to the AuthManager
                try await AuthManager.shared.registerBuyer(
                    email: email,
                    password: password,
                    fullName: fullName,
                    volume: typicalVolume,
                    locationName: locationName
                )
                
                DispatchQueue.main.async {
                    onSuccess()
                }
            } catch {
                print("Registration Error: \(error.localizedDescription)")
            }
        }
    }
}
