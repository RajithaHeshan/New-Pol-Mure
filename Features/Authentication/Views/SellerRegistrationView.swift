
import SwiftUI
import MapKit
import PhotosUI

struct SellerRegistrationView: View {
    @Environment(\.dismiss) var dismiss
    
    // Connect to the ViewModel
    @State private var viewModel = SellerRegistrationViewModel()
    
    var body: some View {
        Form {
            // MARK: - HEADER & PHOTO
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Register Your Estate")
                        .font(.title2.bold())
                        .foregroundColor(Color.polmureEmerald)
                    Text("List your coconut harvest and connect directly with high-volume buyers.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                HStack {
                    Spacer()
                    PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                        VStack(spacing: 8) {
                            if let profileImage = viewModel.profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color(UIColor.secondarySystemBackground))
                                        .frame(width: 90, height: 90)
                                        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                                    
                                    Image(systemName: "tree.fill")
                                        .font(.title)
                                        .foregroundColor(Color.orange)
                                }
                            }
                            Text("Add Estate Photo")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .onChange(of: viewModel.selectedPhotoItem) { newItem in
                        Task {
                            await viewModel.loadProfilePhoto(from: newItem)
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .padding(.bottom, 4)
            }
            
            // MARK: - ACCOUNT DETAILS
            Section(header: Text("Owner Details")) {
                TextField("Full Name", text: $viewModel.fullName)
                    .textContentType(.name)
                
                TextField("Email Address", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                
                TextField("Phone Number", text: $viewModel.phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                
                SecureField("Create Password", text: $viewModel.password)
                    .textContentType(.newPassword)
            }
            
            // MARK: - ESTATE PRODUCTION PROFILE
            Section(
                header: Text("Production Cycle"),
                footer: Text("This data helps buyers secure contracts for your future harvests.")
            ) {
                HStack {
                    Text("Yield Per Harvest")
                    Spacer()
                    TextField("e.g. 10000", text: $viewModel.yieldPerHarvest)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(Color.polmureEmerald)
                        .bold()
                    Text("Nuts")
                        .foregroundColor(.secondary)
                }
                
                Stepper(value: $viewModel.harvestDuration, in: 45...120) {
                    HStack {
                        Text("Harvest Cycle")
                        Spacer()
                        Text("Every \(viewModel.harvestDuration) Days")
                            .foregroundColor(Color.orange)
                            .bold()
                    }
                }
                
                DatePicker("Next Harvest Date", selection: $viewModel.nextHarvestDate, in: Date()..., displayedComponents: .date)
                    .tint(Color.orange)
            }
            
            // MARK: - QUALITY & VERIFICATION
            Section(
                header: Text("Quality & Verification"),
                footer: Text("Verified certificates allow you to charge premium prices on the marketplace.")
            ) {
                Picker("Certification Level", selection: $viewModel.certification) {
                    ForEach(viewModel.certifications, id: \.self) { cert in
                        Text(cert).tag(cert)
                    }
                }
                .tint(Color.polmureEmerald)
                
                if viewModel.certification != "Standard (Local Market)" {
                    PhotosPicker(selection: $viewModel.selectedCertItem, matching: .images, photoLibrary: .shared()) {
                        HStack {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.title2)
                                .foregroundColor(viewModel.certImage != nil ? .green : .orange)
                            
                            VStack(alignment: .leading) {
                                Text(viewModel.certImage != nil ? "Document Uploaded" : "Upload Official Certificate")
                                    .font(.headline)
                                    .foregroundColor(viewModel.certImage != nil ? .primary : .orange)
                                Text(viewModel.certImage != nil ? "Tap to change photo" : "Required for verification")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            if let certImage = viewModel.certImage {
                                certImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .transition(.opacity.combined(with: .scale))
                    .onChange(of: viewModel.selectedCertItem) { newItem in
                        Task {
                            await viewModel.loadCertPhoto(from: newItem)
                        }
                    }
                }
            }
            
            // MARK: - PRECISE MAP LOCATION
            Section(
                header: Text("Estate Location"),
                footer: Text("Privacy Protected: Buyers will only see this 5km fuzzy zone. Your exact estate location is locked until Escrow is secured.")
            ) {
                Map(position: .constant(.region(MKCoordinateRegion(center: viewModel.estateLocation, latitudinalMeters: 15000, longitudinalMeters: 15000))), interactionModes: []) {
                    MapCircle(center: viewModel.estateLocation, radius: 5000)
                        .foregroundStyle(Color.orange.opacity(0.3))
                        .stroke(Color.orange, lineWidth: 2)
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                
                .overlay(alignment: .center) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                        .background(Circle().fill(.white))
                }
                .overlay(alignment: .topTrailing) {
                    Button(action: {
                        viewModel.isFullScreenMapPresented = true
                    }) {
                        Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                            .font(.caption.bold())
                            .padding(10)
                            .background(.thickMaterial)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding(12)
                }
                
                HStack {
                    Text("Selected Zone:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(viewModel.locationName)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Join as a Seller")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut, value: viewModel.certification)
        
        .sheet(isPresented: $viewModel.isFullScreenMapPresented) {
            EstateLocationMapScreen(
                estateLocation: $viewModel.estateLocation,
                locationName: $viewModel.locationName
            )
        }
        
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {
                    viewModel.registerSeller()
                }) {
                    Text("Create Seller Account")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(viewModel.isFormValid ? Color.orange : Color(UIColor.systemGray4))
                        .foregroundColor(viewModel.isFormValid ? .white : Color(UIColor.systemGray))
                        .cornerRadius(14)
                        .shadow(color: viewModel.isFormValid ? Color.orange.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                }
                .disabled(!viewModel.isFormValid)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .background(.regularMaterial)
        }
    }
}

#Preview {
    NavigationStack {
        SellerRegistrationView()
    }
}

