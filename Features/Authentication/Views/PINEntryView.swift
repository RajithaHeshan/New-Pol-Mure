import SwiftUI

// Shown when Face ID fails on the lock screen.
// Correct PIN → onUnlocked()
// Forgot PIN  → onForgotPIN() → routes to LoginView for re-authentication
struct PINEntryView: View {

    var onUnlocked: () -> Void
    var onForgotPIN: () -> Void

    @State private var enteredPIN  = ""
    @State private var shake       = false
    @State private var errorMessage = ""
    @State private var attempts    = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.polmureEmerald.opacity(0.10), Color(UIColor.systemBackground)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    // Icon
                    Image(systemName: "lock.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.polmureEmerald)

                    // Title
                    VStack(spacing: 6) {
                        Text("Enter Passcode")
                            .font(.title2.bold())
                        Text("Enter your 4-digit passcode to unlock")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // PIN dots
                    PINDotsView(count: enteredPIN.count)
                        .modifier(ShakeModifier(shake: shake))

                    // Error
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                Spacer()

                // Numpad
                PINPadView(onDigit: handleDigit, onDelete: handleDelete)
                    .padding(.bottom, 24)

                // Forgot PIN
                Button("Forgot Passcode?") {
                    onForgotPIN()
                }
                .font(.subheadline.bold())
                .foregroundColor(.polmureEmerald)
                .padding(.bottom, 40)
            }
        }
    }

    private func handleDigit(_ digit: String) {
        guard enteredPIN.count < 4 else { return }
        enteredPIN += digit
        errorMessage = ""
        if enteredPIN.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                verify()
            }
        }
    }

    private func handleDelete() {
        guard !enteredPIN.isEmpty else { return }
        enteredPIN.removeLast()
        errorMessage = ""
    }

    private func verify() {
        let saved = KeychainHelper.load(forKey: "polmure.pin") ?? ""
        if enteredPIN == saved {
            onUnlocked()
        } else {
            attempts += 1
            triggerShake()
            enteredPIN = ""
            if attempts >= 5 {
                errorMessage = "Too many attempts. Use 'Forgot Passcode?' to reset."
            } else {
                errorMessage = "Incorrect passcode. \(5 - attempts) attempt\(5 - attempts == 1 ? "" : "s") remaining."
            }
        }
    }

    private func triggerShake() {
        shake = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shake = false }
    }
}
