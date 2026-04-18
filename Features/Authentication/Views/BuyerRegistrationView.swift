
import SwiftUI
import MapKit
import PhotosUI

struct BuyerRegistrationView: View {
    @Environment(\.dismiss) var dismiss
    
    
    @State private var viewModel = BuyerRegistrationViewModel()
    
    var body: some View {
        Form {
            
            Section {
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
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.title)
                                        .foregroundColor(Color.polmureEmerald)
                                }
                            }
                            Text("Add Logo / Photo")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .onChange(of: viewModel.selectedPhotoItem) { newItem in
                        Task {
                            await viewModel.loadPhoto(from: newItem)
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .padding(.top, 10)
                .padding(.bottom, 4)
            }
            
            // MARK: - ACCOUNT DETAILS
            Section(header: Text("Account Details")) {
                TextField("Full Name / Business Name", text: $viewModel.fullName)
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
            
            // MARK: - BUSINESS PROFILE
            Section(header: Text("Business Profile")) {
                Picker("Business Type", selection: $viewModel.businessType) {
                    ForEach(viewModel.businessTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .tint(Color.polmureEmerald)
                
                if viewModel.businessType == "Other" {
                    TextField("Please specify business type...", text: $viewModel.customBusinessType)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                HStack {
                    Text("Typical Volume")
                    Spacer()
                    TextField("e.g. 5000", text: $viewModel.typicalVolume)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(Color.polmureEmerald)
                        .bold()
                    
                    Picker("Unit", selection: $viewModel.volumeUnit) {
                        ForEach(viewModel.volumeUnits, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.secondary)
                    .labelsHidden()
                }
            }
            
            // MARK: - SOURCING LOCATION PREVIEW
            Section(header: Text("Sourcing Location")) {
                Map(position: .constant(.region(MKCoordinateRegion(center: viewModel.buyerLocation, latitudinalMeters: 15000, longitudinalMeters: 15000))), interactionModes: []) {
                    MapCircle(center: viewModel.buyerLocation, radius: 5000)
                        .foregroundStyle(Color.blue.opacity(0.3))
                        .stroke(Color.blue, lineWidth: 2)
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                
                .overlay(alignment: .center) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
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
        .navigationTitle("Join as a Buyer")
        .navigationBarTitleDisplayMode(.inline)
        
        .sheet(isPresented: $viewModel.isFullScreenMapPresented) {
           
            BuyerFullScreenLocationPicker(
                buyerLocation: $viewModel.buyerLocation,
                locationName: $viewModel.locationName
            )
        }
        
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {
                    viewModel.registerBuyer(onSuccess: {
                        dismiss()
                    })
                }) {
                    Text("Create Buyer Account")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(viewModel.isFormValid ? Color.polmureEmerald : Color(UIColor.systemGray4))
                        .foregroundColor(viewModel.isFormValid ? .white : Color(UIColor.systemGray))
                        .cornerRadius(14)
                        .shadow(color: viewModel.isFormValid ? Color.polmureEmerald.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                }
                .disabled(!viewModel.isFormValid)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .background(.regularMaterial)
        }
        .animation(.easeInOut, value: viewModel.businessType)
    }
}

#Preview {
    NavigationStack {
        BuyerRegistrationView()
    }
}
