import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var viewModel = AuthViewModel()
    
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("userRole") var userRole: String = ""
    
    @FocusState private var focusedField: Field?
    enum Field { case email, password }
    
    // New State for Registration Navigation
    @State private var showRegistration = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color.polmureEmerald.opacity(0.15), Color(UIColor.systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                
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
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 16) {
                            
                            // MARK: Updated Sign In Button
                            PrimaryButton(title: "Sign In") {
                                focusedField = nil
                                viewModel.signInWithEmail { success, role, errorMsg in
                                    if success {
                                        self.userRole = role
                                        self.isLoggedIn = true
                                    } else {
                                        viewModel.errorMessage = errorMsg
                                    }
                                }
                            }
                            
                            VStack(spacing: 8) {
                                Text("Simulator Routing (Dev Only)").font(.caption2).foregroundColor(.secondary)
                                Picker("Simulate Role", selection: $viewModel.demoRoleSelection) {
                                    Text("Buyer Demo").tag("Buyer")
                                    Text("Seller Demo").tag("Seller")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }.padding(.top, 8)
                            
                            if !viewModel.errorMessage.isEmpty {
                                Text(viewModel.errorMessage).font(.caption).foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                        
                        // MARK: Updated Registration Routing
                        HStack(spacing: 4) {
                            Text("Don't have an account?").foregroundColor(.secondary).font(.subheadline)
                            Button("Register Now") {
                                showRegistration = true
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.polmureEmerald)
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            // MARK: Navigation Routing
            .navigationDestination(isPresented: $showRegistration) {
                if viewModel.demoRoleSelection == "Buyer" {
                    // Note: Ensure you update BuyerRegistrationView's button to call viewModel.registerBuyer { dismiss() }
                    BuyerRegistrationView()
                } else {
                    SellerRegistrationView()
                }
            }
            .navigationDestination(isPresented: $isLoggedIn) {
                if userRole == "BUYER" || userRole == "Buyer" {
                    DiscoveryDashboardView()
                        .navigationBarBackButtonHidden(true)
                } else {
                    SellerDashboardView()
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
