
import SwiftUI
import LocalAuthentication
import FirebaseAuth
import FirebaseFirestore

@Observable
@MainActor
class AuthViewModel {
    var email = ""
    var password = ""
    var errorMessage = ""
    var demoRoleSelection = "Buyer"

    // MARK: - Email/Password Login
    func signInWithEmail(completion: @escaping (Bool, String, String) -> Void) {
        let safeEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                let role = try await AuthManager.shared.loginUser(email: safeEmail, password: password)
                DispatchQueue.main.async { completion(true, role, "") }
            } catch {
                DispatchQueue.main.async { completion(false, "", error.localizedDescription) }
            }
        }
    }

    // MARK: - Face ID Login
    // Step 1: Face ID proves "this is the phone owner"
    // Step 2: Signs into Firebase with email + password (requires fields filled in)
    // Step 3: Session saved → fetchUserProfile() on dashboard finds real name
    func authenticateWithFaceID(completion: @escaping (Bool, String, String) -> Void) {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, "", "Face ID is not available on this device.")
            return
        }

        // Capture credentials before the async boundary
        let capturedEmail    = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let capturedPassword = password
        let capturedRole     = demoRoleSelection

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                               localizedReason: "Sign in to your Polmure account.") { success, _ in
            DispatchQueue.main.async {
                guard success else {
                    completion(false, "", "Face ID failed or was canceled.")
                    return
                }

                Task {
                    do {
                        let role = try await self.loginAfterFaceID(
                            email: capturedEmail,
                            password: capturedPassword,
                            demoRole: capturedRole
                        )
                        completion(true, role, "")
                    } catch {
                        completion(false, "", error.localizedDescription)
                    }
                }
            }
        }
    }

    // After Face ID passes:
    // 1. If email+password are filled → do full Firebase login (simulator + real device)
    // 2. If Firebase already has active session → reuse it
    // 3. Fallback → demo role only (no name will load)
    private func loginAfterFaceID(email: String, password: String, demoRole: String) async throws -> String {

        // Option 1 — email and password are filled in → full Firebase login
        // This guarantees currentUserID is set and name loads correctly
        if !email.isEmpty && !password.isEmpty {
            let role = try await AuthManager.shared.loginUser(email: email, password: password)
            return role
        }

        // Option 2 — Firebase already has a valid active session from previous login
        if let firebaseUser = Auth.auth().currentUser {
            let snapshot = try await Firestore.firestore()
                .collection("users").document(firebaseUser.uid).getDocument()
            let role = snapshot.data()?["role"] as? String ?? "BUYER"
            AuthManager.shared.refreshSession(userId: firebaseUser.uid, role: role)
            return role
        }

        // Option 3 — Simulator with no credentials and no session → demo fallback
        return demoRole == "Buyer" ? "BUYER" : "SELLER"
    }
}
