
import SwiftUI
import FirebaseAuth

@Observable
@MainActor
class AuthViewModel {
    var email = ""
    var password = ""
    var errorMessage = ""
    var isLoading = false

    // MARK: - Email/Password Login
    func signInWithEmail() async -> (success: Bool, role: String) {
        let safeEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !safeEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return (false, "")
        }
        isLoading = true
        errorMessage = ""
        do {
            let role = try await AuthManager.shared.loginUser(email: safeEmail, password: password)
            isLoading = false
            return (true, role)
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return (false, "")
        }
    }

    // MARK: - Forgot Password
    func sendPasswordReset(email: String, completion: @escaping (Bool, String) -> Void) {
        let safeEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !safeEmail.isEmpty else {
            completion(false, "Please enter your email address.")
            return
        }
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: safeEmail)
                completion(true, "")
            } catch {
                completion(false, error.localizedDescription)
            }
        }
    }
}
