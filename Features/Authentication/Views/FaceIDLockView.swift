import SwiftUI
import LocalAuthentication
import FirebaseAuth

// MARK: - Face ID Lock Screen
// Flow:
//   Launch → Face ID auto-triggered
//   Face ID success → onUnlocked()
//   Face ID fail    → PIN entry screen
//   PIN correct     → onUnlocked()
//   Forgot PIN      → LoginView (re-auth) → onPasswordLogin()
//   "Use Password"  → LoginView → onPasswordLogin()
struct FaceIDLockView: View {

    var onUnlocked: (() -> Void)? = nil
    var onPasswordLogin: (() -> Void)? = nil

    @AppStorage("userRole")        private var userRole    = ""
    @AppStorage("isFaceIDEnabled") private var isFaceIDEnabled = false

    @State private var screen: Screen = .faceID
    @State private var errorMessage   = ""
    @State private var isAuthenticating = false

    enum Screen { case faceID, pin, login }

    var body: some View {
        switch screen {
        case .faceID:
            lockScreen
                .onAppear { authenticate() }

        case .pin:
            PINEntryView(
                onUnlocked: {
                    refreshSession()
                    onUnlocked?()
                },
                onForgotPIN: {
                    screen = .login
                }
            )

        case .login:
            LoginView(onLoginSuccess: {
                onPasswordLogin?()
            })
        }
    }

    // MARK: - Face ID lock UI
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

                VStack(spacing: 12) {
                    Image(systemName: "leaf.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .foregroundColor(.polmureEmerald)
                    Text("Polmure")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }

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

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                VStack(spacing: 12) {
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

                    Button {
                        screen = .pin
                    } label: {
                        Text("Use Passcode")
                            .font(.subheadline.bold())
                            .foregroundColor(.polmureEmerald)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .padding(.horizontal, 24)

                    Button {
                        screen = .login
                    } label: {
                        Text("Use Password Instead")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Face ID
    private func authenticate() {
        let context = LAContext()
        var nsError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &nsError) else {
            // Biometrics not available — stay on Face ID screen, show message
            errorMessage = "Face ID not available. Use Passcode to continue."
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
                    refreshSession()
                    onUnlocked?()
                } else if let err = error as? LAError {
                    switch err.code {
                    case .userCancel, .appCancel, .systemCancel:
                        break
                    case .biometryLockout, .authenticationFailed, .biometryNotAvailable, .biometryNotEnrolled:
                        screen = .pin
                    default:
                        screen = .pin
                    }
                }
            }
        }
    }

    private func refreshSession() {
        if let firebaseUser = Auth.auth().currentUser {
            AuthManager.shared.refreshSession(userId: firebaseUser.uid, role: userRole)
        }
    }
}
