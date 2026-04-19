import SwiftUI
import MapKit

@Observable
@MainActor
class SellerRegistrationViewModel {
   
    var fullName = ""
    var email = ""
    var phone = ""
    var password = ""
    
    
    var yieldPerHarvest = ""
    var harvestCycle = "Every 45 Days"
    var nextHarvestDate = Date()
    
  
    var certificationLevel = "Standard (Local Market)"
    let certificationLevels = ["Standard (Local Market)", "Export Quality", "Organic Certified", "GAP Certified"]
    

    var estateLocation = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609)
    var locationName = "Kurunegala"
    var isFullScreenMapPresented = false
    
   
    var isFormValid: Bool {
        return !fullName.isEmpty &&
               !email.isEmpty && email.contains("@") &&
               !phone.isEmpty &&
               password.count >= 6 &&
               !yieldPerHarvest.isEmpty
    }
    
   
    func registerSeller(onSuccess: @escaping () -> Void) {
      
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
                    locationName: locationName,
                    latitude: estateLocation.latitude,
                    longitude: estateLocation.longitude
                )

                DispatchQueue.main.async { onSuccess() }
            } catch {
                print("Seller Registration Error: \(error.localizedDescription)")
            }
        }
    }
}

