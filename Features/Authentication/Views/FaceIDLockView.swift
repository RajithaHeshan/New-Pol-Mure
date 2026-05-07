import SwiftUI
import LocalAuthentication
import FirebaseAuth

// MARK: - Face ID Lock Screen
// Shown every time the app launches when the user has Face ID enabled.
// Success  → navigates to home (BuyerTabView / SellerTabView)
// Fallback → "Use Password" button → LoginView (email + password)
struct FaceIDLockView: View {

    @AppStorage("userRole")        private var userRole        = ""
    @AppStorage("isLoggedIn")      private var isLoggedIn      = false
    @AppStorage("isFaceIDEnabled") private var isFaceIDEnabled = false

    @State private var unlocked      = false
    @State private var showLogin     = false
    @State private var errorMessage  = ""
    @State private var isAuthenticating = false

    var body: some View {
        Group {
            if unlocked {
                homeView
            } else if showLogin {
                LoginView()
            } else {
                lockScreen
            }
        }
        .onAppear {
            #if !targetEnvironment(simulator)
            authenticate()
            #endif
        }
    }

    // MARK: - Lock screen UI
    private var lockScreen: some View {
        ZStack {
            LinearGradient(
                colors: [Color.polmureEmerald.opacity(0.12), Color(UIColor.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // App icon area
                VStack(spacing: 12) {
                    Image(systemName: "leaf.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .foregroundColor(.polmureEmerald)

                    Text("Polmure")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }

                // Face ID icon
                VStack(spacing: 16) {
                    Image(systemName: "faceid")
                        .font(.system(size: 60))
                        .foregroundColor(.polmureEmerald)

                    Text("Sign in with Face ID")
                        .font(.title3.bold())

                    Text("Use Face ID to access your account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    // Retry Face ID
                    Button {
                        authenticate()
                    } label: {
                        HStack(spacing: 10) {
                            if isAuthenticating {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "faceid")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Unlock with Face ID")
                                    .font(.body.bold())
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.polmureEmerald)
                        .cornerRadius(14)
                    }
                    .disabled(isAuthenticating)
                    .padding(.horizontal, 24)
                    .accessibilityLabel("Unlock with Face ID")

                    // Use password fallback — HIG: always provide a non-biometric path
                    Button {
                        showLogin = true
                    } label: {
                        Text("Use Password Instead")
                            .font(.subheadline.bold())
                            .foregroundColor(.polmureEmerald)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .padding(.horizontal, 24)
                    .accessibilityLabel("Use Password Instead")
                    .accessibilityHint("Opens the email and password login screen")
                }
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Face ID authentication
    private func authenticate() {
        #if targetEnvironment(simulator)
        if let firebaseUser = Auth.auth().currentUser {
            AuthManager.shared.refreshSession(userId: firebaseUser.uid, role: userRole)
        }
        unlocked = true
        return
        #endif

        let context = LAContext()
        var nsError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &nsError) else {
            errorMessage = "Face ID is not available. Use your password."
            return
        }

        isAuthenticating = true
        errorMessage = ""

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Unlock your Polmure account"
        ) { success, error in
            Task { @MainActor in
                isAuthenticating = false
                if success {
                    if let firebaseUser = Auth.auth().currentUser {
                        AuthManager.shared.refreshSession(
                            userId: firebaseUser.uid,
                            role: userRole
                        )
                    }
                    unlocked = true
                } else {
                    if let err = error as? LAError, err.code == .userFallback {
                        showLogin = true
                    } else {
                        errorMessage = "Face ID failed. Try again or use your password."
                    }
                }
            }
        }
    }

    // MARK: - Home view (role-based)
    @ViewBuilder
    private var homeView: some View {
        if userRole == "BUYER" || userRole == "Buyer" {
            BuyerTabView()
        } else {
            SellerTabView()
        }
    }
}
