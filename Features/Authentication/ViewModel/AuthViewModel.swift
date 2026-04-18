
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
        Task {
            do {
                // 1. Pass credentials to the Hybrid Data Manager
                // This checks Firebase Auth, gets the user's role from Firestore, and saves to Core Data
                let role = try await AuthManager.shared.loginUser(email: email, password: password)
                
                // 2. Return success and the user's role to the View to trigger navigation
                DispatchQueue.main.async {
                    completion(true, role, "")
                }
            } catch {
                // 3. Return the exact Firebase error (e.g., "Wrong password") to display in the UI
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
