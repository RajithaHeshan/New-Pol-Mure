import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AuthViewModel()

    @State private var email        = ""
    @State private var isSending    = false
    @State private var emailSent    = false
    @State private var errorMessage = ""

    @FocusState private var emailFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.polmureEmerald.opacity(0.12), Color(UIColor.systemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if emailSent {
                    sentConfirmation
                } else {
                    emailEntryForm
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.polmureEmerald)
                }
            }
        }
    }

    // MARK: - Email Entry Form
    private var emailEntryForm: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {

                // Icon + description
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.polmureEmerald.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.polmureEmerald)
                    }
                    .padding(.top, 40)

                    Text("Forgot your password?")
                        .font(.title2.bold())

                    Text("Enter the email address linked to your account and we'll send you a reset link.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                        TextField("Email Address", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($emailFocused)
                            .submitLabel(.send)
                            .onSubmit { sendReset() }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(14)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 24)

                // Send button
                Button(action: sendReset) {
                    HStack(spacing: 10) {
                        if isSending {
                            ProgressView().tint(.white)
                        } else {
                            Text("Send Reset Link")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(canSend ? Color.polmureEmerald : Color.polmureEmerald.opacity(0.4))
                    .cornerRadius(14)
                    .shadow(color: Color.polmureEmerald.opacity(canSend ? 0.3 : 0), radius: 8, x: 0, y: 4)
                }
                .disabled(!canSend || isSending)
                .padding(.horizontal, 24)
                .animation(.easeInOut(duration: 0.2), value: canSend)

                Spacer(minLength: 40)
            }
        }
        .onAppear { emailFocused = true }
    }

    // MARK: - Sent Confirmation Screen
    private var sentConfirmation: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.green)
            }

            VStack(spacing: 12) {
                Text("Check your inbox")
                    .font(.title2.bold())

                Text("We've sent a password reset link to\n**\(email)**")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text("The link expires in 1 hour. Check your spam folder if you don't see it.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            VStack(spacing: 12) {
                // Back to login — primary action
                Button(action: { dismiss() }) {
                    Text("Back to Sign In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.polmureEmerald)
                        .cornerRadius(14)
                        .shadow(color: Color.polmureEmerald.opacity(0.3), radius: 8, x: 0, y: 4)
                }

                // Resend — secondary action
                Button(action: { emailSent = false }) {
                    Text("Resend Email")
                        .font(.subheadline.bold())
                        .foregroundColor(.polmureEmerald)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Helpers
    private var canSend: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines).contains("@")
    }

    private func sendReset() {
        guard canSend, !isSending else { return }
        emailFocused = false
        errorMessage = ""
        isSending = true

        viewModel.sendPasswordReset(email: email) { success, error in
            isSending = false
            if success {
                emailSent = true
            } else {
                errorMessage = error
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
}
