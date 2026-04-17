// Location: New-Pol-Mure/Features/Authentication/ViewModels/AuthViewModel.swift

import SwiftUI
import LocalAuthentication

@Observable
@MainActor
class AuthViewModel {
    // With @Observable, standard variables automatically update the UI. No @Published needed.
    var email = ""
    var password = ""
    var errorMessage = ""
    var demoRoleSelection = "Buyer"
    
    // Extracted Face ID Logic
    func authenticateWithFaceID(completion: @escaping (Bool, String) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Log in to your Polmure account."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    if success {
                        completion(true, "")
                    } else {
                        completion(false, "Face ID failed or was canceled.")
                    }
                }
            }
        } else {
            completion(false, "Face ID is not available on this device.")
        }
    }
}
