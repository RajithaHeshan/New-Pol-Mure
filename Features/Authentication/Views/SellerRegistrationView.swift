import SwiftUI
import MapKit

struct SellerRegistrationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var viewModel = SellerRegistrationViewModel()
    
    // Dynamic camera state for the inline map
    @State private var inlineCameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609),
        latitudinalMeters: 5000,
        longitudinalMeters: 5000
    ))
    
    var body: some View {
        Form {
            // MARK: - Header & Default Estate Image
            Section {
                VStack(spacing: 8) {
                    HStack {
                        Spacer()
                        Image("Gemini_Generated_Image_bvc5lzbvc5lzbvc5")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                        Spacer()
                    }
                    Text("Default Estate Photo Selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            
            // MARK: - Owner Details
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
            
            // MARK: - Production Cycle
            Section(header: Text("Production Cycle")) {
                HStack {
                    Text("Yield Per Harvest")
                    Spacer()
                    TextField("e.g. 10000", text: $viewModel.yieldPerHarvest)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .foregroundColor(.green)
                    Text("Nuts")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Harvest Cycle")
                    Spacer()
                    Text(viewModel.harvestCycle)
                        .foregroundColor(.secondary)
                }
                
                DatePicker("Next Harvest Date", selection: $viewModel.nextHarvestDate, displayedComponents: .date)
            }
            
            // MARK: - Quality & Verification
            Section(header: Text("Quality & Verification")) {
                Picker("Certification Level", selection: $viewModel.certificationLevel) {
                    ForEach(viewModel.certificationLevels, id: \.self) {
                        Text($0)
                    }
                }
                .tint(.green)
            }
            
            // MARK: - Estate Location (Perfect Edge-to-Edge Map UI)
            Section(header: Text("Estate Location")) {
                ZStack {
                    Map(position: $inlineCameraPosition, interactionModes: []) {
                        MapCircle(center: viewModel.estateLocation, radius: 2000)
                            .foregroundStyle(.orange.opacity(0.3))
                        Marker("Estate", coordinate: viewModel.estateLocation)
                            .tint(.orange)
                    }
                    .frame(height: 140)
                    
                    // Invisible button for tap detection
                    Button(action: { viewModel.isFullScreenMapPresented = true }) {
                        Color.clear
                    }
                }
                .listRowInsets(EdgeInsets())
                .overlay(alignment: .topTrailing) {
                    Button(action: { viewModel.isFullScreenMapPresented = true }) {
                        Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.orange)
                            .frame(width: 32, height: 32)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding(12)
                    .buttonStyle(PlainButtonStyle())
                }
                
                HStack {
                    Text("Selected Zone:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(viewModel.locationName)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }
            }
            
            // MARK: - Submit Button
            Section {
                Button(action: {
                    viewModel.registerSeller {
                        dismiss()
                    }
                }) {
                    Text("Create Seller Account")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(viewModel.isFormValid ? Color(UIColor.systemGray4) : Color(UIColor.systemGray5))
                        .foregroundColor(viewModel.isFormValid ? .primary : Color(UIColor.systemGray))
                        .cornerRadius(14)
                }
                .disabled(!viewModel.isFormValid)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Join as a Seller")
        .navigationBarTitleDisplayMode(.inline)
        // MARK: Using your perfectly working EstateLocationMapScreen!
        .sheet(isPresented: $viewModel.isFullScreenMapPresented) {
            EstateLocationMapScreen(estateLocation: $viewModel.estateLocation, locationName: $viewModel.locationName)
        }
        // Safely updates the inline map without crashing
        .onChange(of: viewModel.locationName) { _, _ in
            inlineCameraPosition = .region(MKCoordinateRegion(
                center: viewModel.estateLocation,
                latitudinalMeters: 5000,
                longitudinalMeters: 5000
            ))
        }
    }
}

#Preview {
    SellerRegistrationView()
}
