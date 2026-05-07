
import SwiftUI
import FirebaseAuth

@Observable
@MainActor
class AuthViewModel {
    var email = ""
    var password = ""
    var errorMessage = ""

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
                DispatchQueue.main.async { completion(true, "") }
            } catch {
                DispatchQueue.main.async { completion(false, error.localizedDescription) }
            }
        }
    }
}
