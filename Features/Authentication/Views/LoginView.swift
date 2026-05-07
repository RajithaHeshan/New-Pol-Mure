import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var viewModel = AuthViewModel()

    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("userRole")   private var userRole:   String = ""

    @FocusState private var focusedField: Field?
    enum Field { case email, password }

    @State private var showRegistration       = false
    @State private var showRegistrationPicker = false
    @State private var registerAsSeller       = false
    @State private var showForgotPassword     = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.polmureEmerald.opacity(0.15), Color(UIColor.systemBackground)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        PolmureHeaderView()

                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "envelope.fill").foregroundColor(.secondary).frame(width: 24)
                                TextField("Email Address", text: $viewModel.email)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .focused($focusedField, equals: .email)
                            }
                            .padding().background(Color(UIColor.secondarySystemBackground)).cornerRadius(14)

                            HStack {
                                Image(systemName: "lock.fill").foregroundColor(.secondary).frame(width: 24)
                                SecureField("Password", text: $viewModel.password)
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .password)
                            }
                            .padding().background(Color(UIColor.secondarySystemBackground)).cornerRadius(14)

                            // Forgot password — right-aligned below password field (HIG standard)
                            HStack {
                                Spacer()
                                Button("Forgot Password?") { showForgotPassword = true }
                                    .font(.subheadline)
                                    .foregroundColor(.polmureEmerald)
                            }
                        }
                        .padding(.horizontal, 24)

                        VStack(spacing: 16) {
                            PrimaryButton(title: "Sign In") {
                                focusedField = nil
                                viewModel.signInWithEmail { success, role, errorMsg in
                                    if success {
                                        userRole   = role
                                        isLoggedIn = true
                                        // SplashView observes isLoggedIn and re-routes to home
                                    } else {
                                        viewModel.errorMessage = errorMsg
                                    }
                                }
                            }

                            if !viewModel.errorMessage.isEmpty {
                                Text(viewModel.errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 40)

                        HStack(spacing: 4) {
                            Text("Don't have an account?").foregroundColor(.secondary).font(.subheadline)
                            Button("Register Now") { showRegistrationPicker = true }
                                .font(.subheadline.bold())
                                .foregroundColor(.polmureEmerald)
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .confirmationDialog("Register as", isPresented: $showRegistrationPicker, titleVisibility: .visible) {
                Button("Buyer")  { registerAsSeller = false; showRegistration = true }
                Button("Seller") { registerAsSeller = true;  showRegistration = true }
                Button("Cancel", role: .cancel) {}
            }
            .navigationDestination(isPresented: $showRegistration) {
                if registerAsSeller { SellerRegistrationView() } else { BuyerRegistrationView() }
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
}

#Preview {
    LoginView()
}
