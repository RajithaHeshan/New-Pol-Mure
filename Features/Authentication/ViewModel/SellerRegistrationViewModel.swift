
// Location: New-Pol-Mure/Features/Authentication/ViewModels/SellerRegistrationViewModel.swift

import SwiftUI
import MapKit
import PhotosUI

@Observable
@MainActor
class SellerRegistrationViewModel {
    // Owner Details
    var fullName = ""
    var email = ""
    var phone = ""
    var password = ""
    
    // Profile Image
    var selectedPhotoItem: PhotosPickerItem? = nil
    var profileImage: Image? = nil
    
    // Production Cycle
    var yieldPerHarvest = ""
    var harvestDuration: Int = 45
    var nextHarvestDate = Date()
    
    // Quality & Verification
    var certification = "Standard (Local Market)"
    var selectedCertItem: PhotosPickerItem? = nil
    var certImage: Image? = nil
    
    // Map State
    var estateLocation = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609)
    var locationName = "Kurunegala"
    var isFullScreenMapPresented = false
    
    // Constants
    let certifications = [
        "Standard (Local Market)",
        "Premium (Export Grade)",
        "Certified Organic",
        "GAP Certified"
    ]
    
    // Validation Logic
    var isFormValid: Bool {
        let isBaseValid = !fullName.isEmpty &&
                          !email.isEmpty && email.contains("@") &&
                          !phone.isEmpty &&
                          !password.isEmpty && password.count >= 6 &&
                          !yieldPerHarvest.isEmpty
        
        // If they select a premium cert, they MUST upload an image for the button to turn Orange
        if certification != "Standard (Local Market)" {
            return isBaseValid && certImage != nil
        }
        return isBaseValid
    }
    
    // Photo Processing Handlers
    func loadProfilePhoto(from item: PhotosPickerItem?) async {
        if let data = try? await item?.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            self.profileImage = Image(uiImage: uiImage)
        }
    }
    
    func loadCertPhoto(from item: PhotosPickerItem?) async {
        if let data = try? await item?.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            self.certImage = Image(uiImage: uiImage)
        }
    }
    
    func registerSeller() {
        // Firebase registration logic will be injected here next
        print("Registering Seller...")
    }
}
