import SwiftUI
import MapKit

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ProfileViewModel()

    @State private var inlineCameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609),
        latitudinalMeters: 5000, longitudinalMeters: 5000
    ))

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else {
                    formView
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $viewModel.isMapPresented) { mapSheet }
            .onChange(of: viewModel.locationName) { _, _ in
                inlineCameraPosition = .region(MKCoordinateRegion(
                    center: viewModel.coordinate,
                    latitudinalMeters: 5000, longitudinalMeters: 5000
                ))
            }
            .alert("Unable to Save", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .overlay { if viewModel.saveSuccess { successOverlay } }
        }
        .onAppear { viewModel.load() }
    }

   
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading profile...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

   
    private var formView: some View {
        Form {
            profileHeaderSection
            personalInfoSection
            if viewModel.isSeller {
                sellerProductionSection
                estateLocationSection
            } else {
                buyerBusinessSection
                buyerLocationSection
            }
            dangerZoneSection
        }
    }

   
    private var profileHeaderSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(viewModel.profileImageName.isEmpty ? "person.circle" : viewModel.profileImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(viewModel.isSeller ? Color.green : Color.blue, lineWidth: 2))
                        .shadow(radius: 4)

                    VStack(spacing: 2) {
                        Text(viewModel.fullName.isEmpty ? "Your Name" : viewModel.fullName)
                            .font(.headline)
                        Text(viewModel.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.isSeller ? "Seller Account" : "Buyer Account")
                            .font(.caption2.bold())
                            .foregroundColor(viewModel.isSeller ? .green : .blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background((viewModel.isSeller ? Color.green : Color.blue).opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Personal Info
    private var personalInfoSection: some View {
        Section(header: Text("Personal Information")) {
            HStack {
                Label("Full Name", systemImage: "person.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 130, alignment: .leading)
                TextField("Enter your name", text: $viewModel.fullName)
                    .multilineTextAlignment(.trailing)
                    .textContentType(.name)
            }

            HStack {
                Label("Phone", systemImage: "phone.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 130, alignment: .leading)
                TextField("Phone number", text: $viewModel.phone)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
            }

            HStack {
                Label("Email", systemImage: "envelope.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 130, alignment: .leading)
                Text(viewModel.email)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    // MARK: - Seller: Production
    private var sellerProductionSection: some View {
        Section(header: Text("Production Details")) {
            HStack {
                Label("Yield / Harvest", systemImage: "leaf.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 140, alignment: .leading)
                TextField("e.g. 10000", text: $viewModel.typicalYield)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.green)
                Text("Nuts")
                    .foregroundColor(.secondary)
            }

            DatePicker("Next Harvest", selection: $viewModel.nextHarvestDate, displayedComponents: .date)

            Picker("Certification", selection: $viewModel.certificationLevel) {
                ForEach(viewModel.certificationLevels, id: \.self) { Text($0) }
            }
            .tint(.green)
        }
    }

    // MARK: - Seller: Estate Location
    private var estateLocationSection: some View {
        Section(header: Text("Estate Location")) {
            ZStack {
                Map(position: $inlineCameraPosition, interactionModes: []) {
                    MapCircle(center: viewModel.coordinate, radius: 2000)
                        .foregroundStyle(.green.opacity(0.3))
                    Marker("Estate", coordinate: viewModel.coordinate).tint(.green)
                }
                .frame(height: 140)
                Button(action: { viewModel.isMapPresented = true }) { Color.clear }
            }
            .listRowInsets(EdgeInsets())
            .overlay(alignment: .topTrailing) {
                Button(action: { viewModel.isMapPresented = true }) {
                    Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .padding(12)
                .buttonStyle(PlainButtonStyle())
            }

            HStack {
                Text("Selected Zone")
                    .foregroundColor(.secondary)
                Spacer()
                Text(viewModel.locationName)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    // MARK: - Buyer: Business
    private var buyerBusinessSection: some View {
        Section(header: Text("Business Profile")) {
            Picker("Business Type", selection: $viewModel.businessType) {
                ForEach(viewModel.businessTypes, id: \.self) { Text($0) }
            }
            .tint(.blue)

            HStack {
                Label("Typical Volume", systemImage: "basket.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 140, alignment: .leading)
                TextField("e.g. 5000", text: $viewModel.typicalVolume)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.blue)
                Text("Nuts")
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Buyer: Sourcing Location
    private var buyerLocationSection: some View {
        Section(header: Text("Sourcing Location")) {
            ZStack {
                Map(position: $inlineCameraPosition, interactionModes: []) {
                    MapCircle(center: viewModel.coordinate, radius: 2000)
                        .foregroundStyle(.blue.opacity(0.3))
                    Marker("Zone", coordinate: viewModel.coordinate).tint(.blue)
                }
                .frame(height: 140)
                Button(action: { viewModel.isMapPresented = true }) { Color.clear }
            }
            .listRowInsets(EdgeInsets())
            .overlay(alignment: .topTrailing) {
                Button(action: { viewModel.isMapPresented = true }) {
                    Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .padding(12)
                .buttonStyle(PlainButtonStyle())
            }

            HStack {
                Text("Selected Zone")
                    .foregroundColor(.secondary)
                Spacer()
                Text(viewModel.locationName)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    // MARK: - Danger Zone
    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                viewModel.signOut()
                dismiss()
            } label: {
                HStack {
                    Spacer()
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.headline)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Map Sheet
    @ViewBuilder
    private var mapSheet: some View {
        if viewModel.isSeller {
            EstateLocationMapScreen(
                estateLocation: $viewModel.coordinate,
                locationName: $viewModel.locationName
            )
        } else {
            BuyerFullScreenLocationPicker(
                buyerLocation: $viewModel.coordinate,
                locationName: $viewModel.locationName
            )
        }
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: { viewModel.save() }) {
                if viewModel.isSaving {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Text("Save")
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.isSeller ? .green : .blue)
                }
            }
            .disabled(viewModel.isSaving)
        }
    }

    // MARK: - Save Success Overlay
    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(viewModel.isSeller ? .green : .blue)
            Text("Profile Updated")
                .font(.title2.bold())
            Text("Your changes have been saved.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                viewModel.saveSuccess = false
                dismiss()
            }
        }
    }
}

#Preview {
    ProfileView()
}
