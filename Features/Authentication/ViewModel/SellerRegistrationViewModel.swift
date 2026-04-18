

import SwiftUI
import MapKit

@Observable
@MainActor
class SellerRegistrationViewModel {
    // MARK: - Owner Details
    var fullName = ""
    var email = ""
    var phone = ""
    var password = ""
    
    
    var yieldPerHarvest = ""
    var harvestCycle = "Every 45 Days"
    var nextHarvestDate = Date()
    
  
    var certificationLevel = "Standard (Local Market)"
    let certificationLevels = ["Standard (Local Market)", "Export Quality", "Organic Certified", "GAP Certified"]
    
    // MARK: - Estate Location State
    var estateLocation = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609)
    var locationName = "Kurunegala"
    var isFullScreenMapPresented = false
    
    // MARK: - Validation
    var isFormValid: Bool {
        return !fullName.isEmpty &&
               !email.isEmpty && email.contains("@") &&
               !phone.isEmpty &&
               password.count >= 6 &&
               !yieldPerHarvest.isEmpty
    }
    
    // MARK: - Registration Trigger
    func registerSeller(onSuccess: @escaping () -> Void) {
        // Strip trailing spaces from email
        let safeEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                try await AuthManager.shared.registerSeller(
                    email: safeEmail,
                    password: password,
                    fullName: fullName,
                    phone: phone,
                    yield: yieldPerHarvest,
                    cycle: harvestCycle,
                    nextHarvestDate: nextHarvestDate,
                    certification: certificationLevel,
                    locationName: locationName
                )
                
                DispatchQueue.main.async { onSuccess() }
            } catch {
                print("Seller Registration Error: \(error.localizedDescription)")
            }
        }
    }
}
