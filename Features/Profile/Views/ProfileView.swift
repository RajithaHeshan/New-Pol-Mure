import SwiftUI
import MapKit

// MARK: - Account Root (shown when user taps avatar in toolbar)
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ProfileViewModel()

    private var accentColor: Color { viewModel.isSeller ? .green : .blue }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else {
                    accountList
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(accentColor)
                        .accessibilityLabel("Done")
                        .accessibilityHint("Closes the Account screen")
                }
            }
            .alert("Unable to Save", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .onAppear { viewModel.load() }
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .accessibilityLabel("Loading account information")
            Text("Loading account...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Main Account List (iOS Settings style)
    private var accountList: some View {
        List {
            // Avatar header — not tappable, purely display
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(viewModel.profileImageName.isEmpty ? "person.circle" : viewModel.profileImageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(accentColor, lineWidth: 2.5))
                            .shadow(color: accentColor.opacity(0.25), radius: 6)
                            .accessibilityHidden(true)

                        Text(viewModel.fullName.isEmpty ? "Your Name" : viewModel.fullName)
                            .font(.title3.bold())

                        Text(viewModel.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(viewModel.isSeller ? "Seller Account" : "Buyer Account")
                            .font(.caption.bold())
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(accentColor.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(.vertical, 10)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                // Group the whole header as a single accessible element
                .accessibilityElement(children: .combine)
                .accessibilityLabel({
                    let name = viewModel.fullName.isEmpty ? "Your Name" : viewModel.fullName
                    let role = viewModel.isSeller ? "Seller Account" : "Buyer Account"
                    return "\(name), \(viewModel.email), \(role)"
                }())
            }

            // MARK: Account Section
            Section {
                NavigationLink(destination: PersonalInfoEditView(viewModel: viewModel)) {
                    accountRow(
                        icon: "person.fill",
                        iconColor: .blue,
                        title: "Personal Information",
                        subtitle: viewModel.fullName.isEmpty ? "Name, phone, email" : viewModel.fullName
                    )
                }
                .accessibilityLabel("Personal Information")
                .accessibilityHint(viewModel.fullName.isEmpty ? "Name, phone, and email not set. Double tap to edit." : "Current name: \(viewModel.fullName). Double tap to edit.")

                if viewModel.isSeller {
                    NavigationLink(destination: SellerProductionEditView(viewModel: viewModel)) {
                        accountRow(
                            icon: "leaf.fill",
                            iconColor: .green,
                            title: "Production Details",
                            subtitle: viewModel.typicalYield.isEmpty ? "Yield, harvest date, certification" : "\(viewModel.typicalYield) Nuts"
                        )
                    }
                    .accessibilityLabel("Production Details")
                    .accessibilityHint(viewModel.typicalYield.isEmpty ? "Yield and harvest details not set. Double tap to edit." : "Typical yield: \(viewModel.typicalYield) nuts. Double tap to edit.")

                    NavigationLink(destination: LocationEditView(viewModel: viewModel)) {
                        accountRow(
                            icon: "mappin.and.ellipse",
                            iconColor: .orange,
                            title: "Estate Location",
                            subtitle: viewModel.locationName.isEmpty ? "Set your estate location" : viewModel.locationName
                        )
                    }
                    .accessibilityLabel("Estate Location")
                    .accessibilityHint(viewModel.locationName.isEmpty ? "Location not set. Double tap to choose on map." : "Current location: \(viewModel.locationName). Double tap to change.")
                } else {
                    NavigationLink(destination: BuyerBusinessEditView(viewModel: viewModel)) {
                        accountRow(
                            icon: "briefcase.fill",
                            iconColor: .purple,
                            title: "Business Profile",
                            subtitle: viewModel.businessType.isEmpty ? "Type, typical volume" : viewModel.businessType
                        )
                    }
                    .accessibilityLabel("Business Profile")
                    .accessibilityHint(viewModel.businessType.isEmpty ? "Business type and volume not set. Double tap to edit." : "Business type: \(viewModel.businessType). Double tap to edit.")

                    NavigationLink(destination: LocationEditView(viewModel: viewModel)) {
                        accountRow(
                            icon: "mappin.and.ellipse",
                            iconColor: .orange,
                            title: "Sourcing Location",
                            subtitle: viewModel.locationName.isEmpty ? "Set your sourcing zone" : viewModel.locationName
                        )
                    }
                    .accessibilityLabel("Sourcing Location")
                    .accessibilityHint(viewModel.locationName.isEmpty ? "Location not set. Double tap to choose on map." : "Current location: \(viewModel.locationName). Double tap to change.")
                }
            } header: {
                Text("Account")
            }

            // MARK: Sign Out
            Section {
                Button(role: .destructive) {
                    viewModel.signOut()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .accessibilityHidden(true)
                        Text("Sign Out")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.red)
                }
                .accessibilityLabel("Sign Out")
                .accessibilityHint("Signs you out of your account")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Reusable Account Row
    private func accountRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(iconColor)
                .cornerRadius(7)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Personal Information Edit Screen
struct PersonalInfoEditView: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    private var accentColor: Color { viewModel.isSeller ? .green : .blue }

    var body: some View {
        List {
            Section {
                editRow(icon: "person.fill", label: "Full Name") {
                    TextField("Enter your name", text: $viewModel.fullName)
                        .multilineTextAlignment(.trailing)
                        .textContentType(.name)
                        .accessibilityLabel("Full Name")
                        .accessibilityHint("Enter your full name")
                }
                editRow(icon: "phone.fill", label: "Phone") {
                    TextField("Phone number", text: $viewModel.phone)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .accessibilityLabel("Phone number")
                        .accessibilityHint("Enter your phone number")
                }
                HStack {
                    Label("Email", systemImage: "envelope.fill")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .accessibilityHidden(true)
                    Spacer()
                    Text(viewModel.email)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Email: \(viewModel.email)")
                .accessibilityHint("Email address cannot be changed")
            } footer: {
                Text("Email cannot be changed.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Personal Information")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    viewModel.save()
                    dismiss()
                }
                .fontWeight(.semibold)
                .foregroundColor(accentColor)
                .disabled(viewModel.isSaving)
                .accessibilityLabel("Save personal information")
                .accessibilityHint("Saves your name and phone number")
            }
        }
        .overlay { if viewModel.saveSuccess { saveSuccessOverlay(accentColor: accentColor) } }
    }
}

// MARK: - Seller Production Edit Screen
struct SellerProductionEditView: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                HStack {
                    Label("Yield / Harvest", systemImage: "leaf.fill")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .accessibilityHidden(true)
                    Spacer()
                    TextField("e.g. 10000", text: $viewModel.typicalYield)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.green)
                        .frame(width: 80)
                        .accessibilityLabel("Typical yield in nuts")
                        .accessibilityHint("Enter the number of coconuts you typically harvest")
                    Text("Nuts")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .accessibilityHidden(true)
                }
                DatePicker("Next Harvest", selection: $viewModel.nextHarvestDate, displayedComponents: .date)
                    .tint(.green)
                    .accessibilityLabel("Next harvest date")
                    .accessibilityHint("Select the date of your next expected harvest")
                Picker("Certification", selection: $viewModel.certificationLevel) {
                    ForEach(viewModel.certificationLevels, id: \.self) { Text($0) }
                }
                .tint(.green)
                .accessibilityLabel("Certification level")
                .accessibilityHint("Select your coconut certification level")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Production Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { viewModel.save(); dismiss() }
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .disabled(viewModel.isSaving)
                    .accessibilityLabel("Save production details")
                    .accessibilityHint("Saves yield, harvest date, and certification")
            }
        }
        .overlay { if viewModel.saveSuccess { saveSuccessOverlay(accentColor: .green) } }
    }
}

// MARK: - Buyer Business Edit Screen
struct BuyerBusinessEditView: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                Picker("Business Type", selection: $viewModel.businessType) {
                    ForEach(viewModel.businessTypes, id: \.self) { Text($0) }
                }
                .tint(.blue)
                .accessibilityLabel("Business type")
                .accessibilityHint("Select the type of your business")
                HStack {
                    Label("Typical Volume", systemImage: "basket.fill")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .accessibilityHidden(true)
                    Spacer()
                    TextField("e.g. 5000", text: $viewModel.typicalVolume)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.blue)
                        .frame(width: 80)
                        .accessibilityLabel("Typical purchase volume in nuts")
                        .accessibilityHint("Enter the number of coconuts you typically buy")
                    Text("Nuts")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .accessibilityHidden(true)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Business Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { viewModel.save(); dismiss() }
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .disabled(viewModel.isSaving)
                    .accessibilityLabel("Save business profile")
                    .accessibilityHint("Saves business type and typical volume")
            }
        }
        .overlay { if viewModel.saveSuccess { saveSuccessOverlay(accentColor: .blue) } }
    }
}

// MARK: - Location Edit Screen (shared buyer + seller)
struct LocationEditView: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609),
        latitudinalMeters: 5000, longitudinalMeters: 5000
    ))

    private var accentColor: Color { viewModel.isSeller ? .green : .blue }
    private var title: String { viewModel.isSeller ? "Estate Location" : "Sourcing Location" }

    var body: some View {
        List {
            Section {
                ZStack {
                    Map(position: $cameraPosition, interactionModes: []) {
                        MapCircle(center: viewModel.coordinate, radius: 2000)
                            .foregroundStyle(accentColor.opacity(0.25))
                        Marker(viewModel.isSeller ? "Estate" : "Zone", coordinate: viewModel.coordinate)
                            .tint(accentColor)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    Button(action: { viewModel.isMapPresented = true }) { Color.clear }
                }
                .listRowInsets(EdgeInsets())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(viewModel.locationName.isEmpty
                    ? "Map preview. No location selected."
                    : "Map preview showing \(viewModel.locationName).")
                .accessibilityHint("Double tap to open the full map and pick a location")
                .accessibilityAddTraits(.isButton)
                .overlay(alignment: .topTrailing) {
                    Button(action: { viewModel.isMapPresented = true }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(accentColor)
                            .frame(width: 30, height: 30)
                            .background(Color(UIColor.systemBackground))
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding(10)
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityHidden(true)
                }

                HStack {
                    Label("Selected Zone", systemImage: "location.fill")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .accessibilityHidden(true)
                    Spacer()
                    Text(viewModel.locationName.isEmpty ? "Not set" : viewModel.locationName)
                        .font(.subheadline.bold())
                        .multilineTextAlignment(.trailing)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Selected location: \(viewModel.locationName.isEmpty ? "not set" : viewModel.locationName)")

                Button(action: { viewModel.isMapPresented = true }) {
                    HStack {
                        Spacer()
                        Label("Change Location", systemImage: "map.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(accentColor)
                        Spacer()
                    }
                }
                .accessibilityLabel("Change location")
                .accessibilityHint("Opens the full map to pick a new location")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { viewModel.save(); dismiss() }
                    .fontWeight(.semibold)
                    .foregroundColor(accentColor)
                    .disabled(viewModel.isSaving)
                    .accessibilityLabel("Save location")
                    .accessibilityHint("Saves the selected \(viewModel.isSeller ? "estate" : "sourcing") location")
            }
        }
        .sheet(isPresented: $viewModel.isMapPresented) {
            if viewModel.isSeller {
                EstateLocationMapScreen(estateLocation: $viewModel.coordinate, locationName: $viewModel.locationName)
            } else {
                BuyerFullScreenLocationPicker(buyerLocation: $viewModel.coordinate, locationName: $viewModel.locationName)
            }
        }
        .onChange(of: viewModel.locationName) { _, _ in
            cameraPosition = .region(MKCoordinateRegion(
                center: viewModel.coordinate,
                latitudinalMeters: 5000, longitudinalMeters: 5000
            ))
        }
        .overlay { if viewModel.saveSuccess { saveSuccessOverlay(accentColor: accentColor) } }
    }
}

// MARK: - Shared helper row builder
private func editRow<Content: View>(icon: String, label: String, @ViewBuilder trailing: () -> Content) -> some View {
    HStack(spacing: 10) {
        Image(systemName: icon)
            .foregroundColor(.secondary)
            .font(.subheadline)
            .frame(width: 20)
            .accessibilityHidden(true)
        Text(label)
            .font(.subheadline)
            .foregroundColor(.secondary)
        Spacer()
        trailing()
    }
    .padding(.vertical, 4)
}

// MARK: - Shared save success overlay
private func saveSuccessOverlay(accentColor: Color) -> some View {
    VStack(spacing: 16) {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 60))
            .foregroundColor(accentColor)
            .accessibilityHidden(true)
        Text("Saved")
            .font(.title2.bold())
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.ultraThinMaterial)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Changes saved successfully")
}

#Preview {
    ProfileView()
}
