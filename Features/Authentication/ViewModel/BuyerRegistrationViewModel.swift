
import SwiftUI
import MapKit
import PhotosUI

@Observable
@MainActor
class BuyerRegistrationViewModel {
    // Account Details
    var fullName = ""
    var email = ""
    var phone = ""
    var password = ""
    
    // Profile Image
    var selectedPhotoItem: PhotosPickerItem? = nil
    var profileImage: Image? = nil
    
    // Business Profile
    var businessType = "Retailer / Grocery"
    var customBusinessType = ""
    var typicalVolume = ""
    var volumeUnit = "Nuts"
    
    // Map State
    var buyerLocation = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609)
    var locationName = "Kurunegala"
    var isFullScreenMapPresented = false
    
    // Constants for Pickers
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
    
    // Validation Logic
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
    
    // Photo Processing
    func loadPhoto(from item: PhotosPickerItem?) async {
        if let data = try? await item?.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            self.profileImage = Image(uiImage: uiImage)
        }
    }
    
    func registerBuyer() {
        // Firebase registration logic will be injected here next
        print("Registering Buyer...")
    }
}

