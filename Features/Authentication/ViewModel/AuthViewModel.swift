
import SwiftUI
import LocalAuthentication

@Observable
@MainActor
class AuthViewModel {
    // State Variables for the UI
    var email = ""
    var password = ""
    var errorMessage = ""
    var demoRoleSelection = "Buyer"
    
    // MARK: - Email/Password Login (Firebase + Core Data)
    func signInWithEmail(completion: @escaping (Bool, String, String) -> Void) {
        
        // THE FIX: Strip out invisible trailing spaces added by the iOS keyboard
        let safeEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                // Pass the cleaned credentials to the Hybrid Data Manager
                let role = try await AuthManager.shared.loginUser(email: safeEmail, password: password)
                
                DispatchQueue.main.async {
                    completion(true, role, "")
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, "", error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Face ID Logic
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
