import SwiftUI

// Shown when the user enables Face ID in Profile.
// Step 1: enter new 4-digit PIN
// Step 2: confirm PIN
// On match → saves to Keychain, sets isFaceIDEnabled = true, calls onComplete
struct PINSetupView: View {

    var onComplete: () -> Void
    var onCancel: () -> Void

    @AppStorage("isFaceIDEnabled") private var isFaceIDEnabled = false

    @State private var step: Step = .enter
    @State private var firstPIN  = ""
    @State private var enteredPIN = ""
    @State private var shake = false
    @State private var errorMessage = ""

    enum Step { case enter, confirm }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.polmureEmerald.opacity(0.10), Color(UIColor.systemBackground)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") { onCancel() }
                        .foregroundColor(.polmureEmerald)
                        .font(.body)
                        .padding(.leading, 20)
                    Spacer()
                }
                .padding(.top, 16)

                Spacer()

                VStack(spacing: 28) {
                    // Icon
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.polmureEmerald)

                    // Title
                    VStack(spacing: 6) {
                        Text(step == .enter ? "Set Your Passcode" : "Confirm Passcode")
                            .font(.title2.bold())
                        Text(step == .enter
                             ? "Create a 4-digit passcode as a backup for Face ID"
                             : "Enter the same passcode again to confirm")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // PIN dots
                    PINDotsView(count: enteredPIN.count)
                        .modifier(ShakeModifier(shake: shake))

                    // Error
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Spacer()

                // Numpad
                PINPadView(onDigit: handleDigit, onDelete: handleDelete)
                    .padding(.bottom, 40)
            }
        }
    }

    private func handleDigit(_ digit: String) {
        guard enteredPIN.count < 4 else { return }
        enteredPIN += digit
        if enteredPIN.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                advance()
            }
        }
    }

    private func handleDelete() {
        guard !enteredPIN.isEmpty else { return }
        enteredPIN.removeLast()
        errorMessage = ""
    }

    private func advance() {
        switch step {
        case .enter:
            firstPIN = enteredPIN
            enteredPIN = ""
            errorMessage = ""
            step = .confirm

        case .confirm:
            if enteredPIN == firstPIN {
                KeychainHelper.save(enteredPIN, forKey: "polmure.pin")
                isFaceIDEnabled = true
                onComplete()
            } else {
                triggerShake()
                errorMessage = "Passcodes don't match. Try again."
                enteredPIN = ""
                firstPIN = ""
                step = .enter
            }
        }
    }

    private func triggerShake() {
        shake = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shake = false }
    }
}

