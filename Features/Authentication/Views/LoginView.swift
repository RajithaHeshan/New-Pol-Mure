

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    // Connect to our new ViewModel
    @State private var viewModel = AuthViewModel()
    // Global App State
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("userRole") var userRole: String = ""
    
    @FocusState private var focusedField: Field?
    enum Field { case email, password }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.polmureEmerald.opacity(0.15), Color(UIColor.systemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        
                        // 1. Use Reusable Component
                        PolmureHeaderView()
                        
                        // 2. Input Fields
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "envelope.fill").foregroundColor(.secondary).frame(width: 24)
                                TextField("Email Address", text: $viewModel.email)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .focused($focusedField, equals: .email)
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.1), lineWidth: 1))
                            
                            HStack {
                                Image(systemName: "lock.fill").foregroundColor(.secondary).frame(width: 24)
                                SecureField("Password", text: $viewModel.password)
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .password)
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.1), lineWidth: 1))
                            
                            HStack {
                                Spacer()
                                Button("Forgot Password?") { }
                                    .font(.caption.bold())
                                    .foregroundColor(.polmureEmerald)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // 3. Action Buttons
                        VStack(spacing: 16) {
                            // Use Reusable Component
                            PrimaryButton(title: "Sign In") {
                                focusedField = nil
                                // Add Firebase email login logic here later
                            }
                            
                            // Simulator Role Toggle
                            VStack(spacing: 8) {
                                Text("Simulator Routing (Dev Only)")
                                    .font(.caption2).foregroundColor(.secondary)
                                Picker("Simulate Role", selection: $viewModel.demoRoleSelection) {
                                    Text("Buyer Demo").tag("Buyer")
                                    Text("Seller Demo").tag("Seller")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }.padding(.top, 8)
                            
                            // Face ID Button using ViewModel
                            Button(action: {
                                viewModel.authenticateWithFaceID { success, errorMsg in
                                    if success {
                                        self.userRole = viewModel.demoRoleSelection
                                        self.isLoggedIn = true
                                    } else {
                                        viewModel.errorMessage = errorMsg
                                    }
                                }
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "faceid").font(.title3)
                                    Text("Sign in with Face ID").font(.headline)
                                }
                                .foregroundColor(.polmureEmerald)
                                .frame(maxWidth: .infinity, maxHeight: 54)
                                .background(Color.polmureEmerald.opacity(0.1))
                                .cornerRadius(14)
                            }
                            
                            if !viewModel.errorMessage.isEmpty {
                                Text(viewModel.errorMessage).font(.caption).foregroundColor(.red)
                            }
                            
                            HStack {
                                VStack { Divider() }
                                Text("OR").font(.caption).foregroundColor(.secondary).padding(.horizontal, 8)
                                VStack { Divider() }
                            }.padding(.vertical, 8)
                            
                            SignInWithAppleButton(.signIn, onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            }, onCompletion: { _ in })
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 54)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                        
                        HStack(spacing: 4) {
                            Text("Don't have an account?").foregroundColor(.secondary).font(.subheadline)
                            Button("Register Now") { }.font(.subheadline.bold()).foregroundColor(.polmureEmerald)
                        }.padding(.bottom, 20)
                    }
                }
                .onTapGesture { focusedField = nil }
            }
            .navigationDestination(isPresented: $isLoggedIn) {
                if userRole == "Buyer" {
                    Text("Welcome to the Buyer Discovery Dashboard").navigationBarBackButtonHidden(true)
                } else if userRole == "Seller" {
                    Text("Welcome to the Seller Activity Dashboard").navigationBarBackButtonHidden(true)
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
