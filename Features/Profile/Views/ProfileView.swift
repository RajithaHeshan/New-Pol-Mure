import SwiftUI
import MapKit

// MARK: - Account Root
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var viewModel = ProfileViewModel()

    private var accentColor: Color { viewModel.isSeller ? .green : .blue }

    // High Contrast: increase border width when contrast is elevated
    private var avatarBorderWidth: CGFloat { contrast == .increased ? 4 : 2.5 }

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
                .font(.subheadline)          // Dynamic Type: scales automatically
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Main Account List
    private var accountList: some View {
        List {
            // MARK: Avatar Header
            Section {
                // Dynamic Type: switch to vertical layout at accessibility sizes
                if typeSize.isAccessibilitySize {
                    VStack(spacing: 12) {
                        avatarImage
                        headerTextStack
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                } else {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            avatarImage
                            headerTextStack
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(headerAccessibilityLabel)
            .accessibilityAddTraits(.isStaticText)

            // MARK: Account Section
            Section {
                NavigationLink(destination: PersonalInfoEditView(viewModel: viewModel)) {
                    accountRow(icon: "person.fill", iconColor: .blue,
                               title: "Personal Information",
                               subtitle: viewModel.fullName.isEmpty
                                   ? "Name, phone, email"
                                   : viewModel.fullName)
                }
                .accessibilityLabel("Personal Information")
                .accessibilityHint(
                    viewModel.fullName.isEmpty
                        ? "Not set. Double tap to edit your name, phone, and email."
                        : "Current name: \(viewModel.fullName). Double tap to edit."
                )

                if viewModel.isSeller {
                    NavigationLink(destination: SellerProductionEditView(viewModel: viewModel)) {
                        accountRow(icon: "leaf.fill", iconColor: .green,
                                   title: "Production Details",
                                   subtitle: viewModel.typicalYield.isEmpty
                                       ? "Yield, harvest date, certification"
                                       : "\(viewModel.typicalYield) Nuts")
                    }
                    .accessibilityLabel("Production Details")
                    .accessibilityHint(
                        viewModel.typicalYield.isEmpty
                            ? "Not set. Double tap to edit yield and harvest details."
                            : "Typical yield: \(viewModel.typicalYield) nuts. Double tap to edit."
                    )

                    NavigationLink(destination: LocationEditView(viewModel: viewModel)) {
                        accountRow(icon: "mappin.and.ellipse", iconColor: .orange,
                                   title: "Estate Location",
                                   subtitle: viewModel.locationName.isEmpty
                                       ? "Set your estate location"
                                       : viewModel.locationName)
                    }
                    .accessibilityLabel("Estate Location")
                    .accessibilityHint(
                        viewModel.locationName.isEmpty
                            ? "Not set. Double tap to pick your estate on the map."
                            : "Current location: \(viewModel.locationName). Double tap to change."
                    )
                } else {
                    NavigationLink(destination: BuyerBusinessEditView(viewModel: viewModel)) {
                        accountRow(icon: "briefcase.fill", iconColor: .purple,
                                   title: "Business Profile",
                                   subtitle: viewModel.businessType.isEmpty
                                       ? "Type, typical volume"
                                       : viewModel.businessType)
                    }
                    .accessibilityLabel("Business Profile")
                    .accessibilityHint(
                        viewModel.businessType.isEmpty
                            ? "Not set. Double tap to edit your business type and volume."
                            : "Business type: \(viewModel.businessType). Double tap to edit."
                    )

                    NavigationLink(destination: LocationEditView(viewModel: viewModel)) {
                        accountRow(icon: "mappin.and.ellipse", iconColor: .orange,
                                   title: "Sourcing Location",
                                   subtitle: viewModel.locationName.isEmpty
                                       ? "Set your sourcing zone"
                                       : viewModel.locationName)
                    }
                    .accessibilityLabel("Sourcing Location")
                    .accessibilityHint(
                        viewModel.locationName.isEmpty
                            ? "Not set. Double tap to pick your sourcing zone on the map."
                            : "Current location: \(viewModel.locationName). Double tap to change."
                    )
                }
            } header: {
                Text("Account")                // Dynamic Type: section headers scale automatically
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
                            .font(.body)       // Dynamic Type: scales automatically
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

    // MARK: - Avatar Image (extracted for reuse in both layout branches)
    private var avatarImage: some View {
        Image(viewModel.profileImageName.isEmpty ? "person.circle" : viewModel.profileImageName)
            .resizable()
            .scaledToFill()
            .frame(width: 72, height: 72)
            .clipShape(Circle())
            // High Contrast: thicker border, full-opacity shadow removed
            .overlay(
                Circle().stroke(
                    contrast == .increased ? accentColor : accentColor,
                    lineWidth: avatarBorderWidth
                )
            )
            .shadow(
                color: contrast == .increased ? .clear : accentColor.opacity(0.25),
                radius: contrast == .increased ? 0 : 6
            )
            .accessibilityHidden(true)
    }

    // MARK: - Header Text Stack
    private var headerTextStack: some View {
        VStack(spacing: 6) {
            Text(viewModel.fullName.isEmpty ? "Your Name" : viewModel.fullName)
                .font(.title3.bold())          // Dynamic Type: scales automatically
                .multilineTextAlignment(.center)

            Text(viewModel.email)
                .font(.subheadline)            // Dynamic Type: scales automatically
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text(viewModel.isSeller ? "Seller Account" : "Buyer Account")
                .font(.caption.bold())         // Dynamic Type: scales automatically
                // High Contrast: use full opacity color instead of tinted background
                .foregroundColor(contrast == .increased ? .primary : accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    contrast == .increased
                        ? AnyShapeStyle(accentColor)           // solid background for contrast
                        : AnyShapeStyle(accentColor.opacity(0.1))
                )
                .foregroundColor(contrast == .increased ? .white : accentColor)
                .clipShape(Capsule())
                // High Contrast: add a border around the badge
                .overlay(
                    contrast == .increased
                        ? AnyView(Capsule().stroke(accentColor, lineWidth: 1.5))
                        : AnyView(EmptyView())
                )
        }
    }

    private var headerAccessibilityLabel: String {
        let name = viewModel.fullName.isEmpty ? "Your Name" : viewModel.fullName
        let role = viewModel.isSeller ? "Seller Account" : "Buyer Account"
        return "\(name), \(viewModel.email), \(role)"
    }

    // MARK: - Reusable Account Row
    private func accountRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        // Dynamic Type: at accessibility sizes stack vertically instead of side by side
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    iconBadge(icon: icon, iconColor: iconColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.body)
                            .foregroundColor(.primary)
                        Text(subtitle)
                            .font(.subheadline)   // larger than caption at accessibility sizes
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 6)
            } else {
                HStack(spacing: 14) {
                    iconBadge(icon: icon, iconColor: iconColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.body)          // Dynamic Type: scales automatically
                            .foregroundColor(.primary)
                        Text(subtitle)
                            .font(.caption)       // Dynamic Type: scales automatically
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // Icon badge extracted so both layout branches share it
    private func iconBadge(icon: String, iconColor: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 30, height: 30)
            .background(iconColor)
            .cornerRadius(7)
            // High Contrast: add a visible border around the icon badge
            .overlay(
                contrast == .increased
                    ? AnyView(RoundedRectangle(cornerRadius: 7).stroke(iconColor, lineWidth: 1.5))
                    : AnyView(EmptyView())
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Personal Information Edit Screen
struct PersonalInfoEditView: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorSchemeContrast) private var contrast
    private var accentColor: Color { viewModel.isSeller ? .green : .blue }

    var body: some View {
        List {
            Section {
                // Dynamic Type: stack label above field at accessibility sizes
                editRow(icon: "person.fill", label: "Full Name", typeSize: typeSize) {
                    TextField("Enter your name", text: $viewModel.fullName)
                        .multilineTextAlignment(typeSize.isAccessibilitySize ? .leading : .trailing)
                        .textContentType(.name)
                        .accessibilityLabel("Full Name")
                        .accessibilityValue(viewModel.fullName.isEmpty ? "Not set" : viewModel.fullName)
                        .accessibilityHint("Enter your full name")
                }

                editRow(icon: "phone.fill", label: "Phone", typeSize: typeSize) {
                    TextField("Phone number", text: $viewModel.phone)
                        .multilineTextAlignment(typeSize.isAccessibilitySize ? .leading : .trailing)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .accessibilityLabel("Phone number")
                        .accessibilityValue(viewModel.phone.isEmpty ? "Not set" : viewModel.phone)
                        .accessibilityHint("Enter your contact phone number")
                }

                // Email — read only
                // High Contrast: show a visible border to distinguish read-only field
                HStack {
                    Label("Email", systemImage: "envelope.fill")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .accessibilityHidden(true)
                    Spacer()
                    Text(viewModel.email)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .padding(contrast == .increased ? 6 : 0)
                .background(
                    contrast == .increased
                        ? AnyShapeStyle(Color.secondary.opacity(0.08))
                        : AnyShapeStyle(Color.clear)
                )
                .cornerRadius(contrast == .increased ? 6 : 0)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Email")
                .accessibilityValue(viewModel.email)
                .accessibilityHint("Email address cannot be changed")

            } footer: {
                Text("Email cannot be changed.")
                    .font(.footnote)           // Dynamic Type: scales automatically
                    .accessibilityHidden(true)
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
                .accessibilityLabel("Save")
                .accessibilityHint("Saves your updated name and phone number")
            }
        }
        .overlay {
            if viewModel.saveSuccess { saveSuccessOverlay(accentColor: accentColor) }
        }
    }
}

// MARK: - Seller Production Edit Screen
struct SellerProductionEditView: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        List {
            Section {
                // Dynamic Type: stack at accessibility sizes
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Yield / Harvest")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack {
                            TextField("e.g. 10000", text: $viewModel.typicalYield)
                                .keyboardType(.numberPad)
                                .foregroundColor(.green)
                                .accessibilityLabel("Typical yield")
                                .accessibilityValue(viewModel.typicalYield.isEmpty ? "Not set" : "\(viewModel.typicalYield) nuts")
                                .accessibilityHint("Enter the number of coconuts you typically harvest")
                            Text("Nuts").foregroundColor(.secondary).font(.subheadline)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.vertical, 4)
                } else {
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
                            .accessibilityLabel("Typical yield")
                            .accessibilityValue(viewModel.typicalYield.isEmpty ? "Not set" : "\(viewModel.typicalYield) nuts")
                            .accessibilityHint("Enter the number of coconuts you typically harvest")
                        Text("Nuts").foregroundColor(.secondary).font(.subheadline)
                            .accessibilityHidden(true)
                    }
                }

                DatePicker(
                    "Next Harvest Date",
                    selection: $viewModel.nextHarvestDate,
                    displayedComponents: .date
                )
                .tint(.green)
                .accessibilityLabel("Next harvest date")
                .accessibilityValue(viewModel.nextHarvestDate.formatted(date: .abbreviated, time: .omitted))
                .accessibilityHint("Select the expected date of your next coconut harvest")

                Picker("Certification", selection: $viewModel.certificationLevel) {
                    ForEach(viewModel.certificationLevels, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
                .tint(.green)
                .accessibilityLabel("Certification level")
                .accessibilityValue(viewModel.certificationLevel)
                .accessibilityHint("Select the certification level that applies to your produce")

            } header: {
                Text("Harvest Information")
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
                    .accessibilityLabel("Save")
                    .accessibilityHint("Saves yield, harvest date, and certification details")
            }
        }
        .overlay {
            if viewModel.saveSuccess { saveSuccessOverlay(accentColor: .green) }
        }
    }
}

// MARK: - Buyer Business Edit Screen
struct BuyerBusinessEditView: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        List {
            Section {
                Picker("Business Type", selection: $viewModel.businessType) {
                    ForEach(viewModel.businessTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .tint(.blue)
                .accessibilityLabel("Business type")
                .accessibilityValue(viewModel.businessType.isEmpty ? "Not selected" : viewModel.businessType)
                .accessibilityHint("Select the category that best describes your business")

                // Dynamic Type: stack at accessibility sizes
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Typical Volume")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack {
                            TextField("e.g. 5000", text: $viewModel.typicalVolume)
                                .keyboardType(.numberPad)
                                .foregroundColor(.blue)
                                .accessibilityLabel("Typical purchase volume")
                                .accessibilityValue(viewModel.typicalVolume.isEmpty ? "Not set" : "\(viewModel.typicalVolume) nuts")
                                .accessibilityHint("Enter the number of coconuts you typically buy per order")
                            Text("Nuts").foregroundColor(.secondary).font(.subheadline)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.vertical, 4)
                } else {
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
                            .accessibilityLabel("Typical purchase volume")
                            .accessibilityValue(viewModel.typicalVolume.isEmpty ? "Not set" : "\(viewModel.typicalVolume) nuts")
                            .accessibilityHint("Enter the number of coconuts you typically buy per order")
                        Text("Nuts").foregroundColor(.secondary).font(.subheadline)
                            .accessibilityHidden(true)
                    }
                }
            } header: {
                Text("Business Information")
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
                    .accessibilityLabel("Save")
                    .accessibilityHint("Saves your business type and typical purchase volume")
            }
        }
        .overlay {
            if viewModel.saveSuccess { saveSuccessOverlay(accentColor: .blue) }
        }
    }
}

// MARK: - Location Edit Screen (shared buyer + seller)
struct LocationEditView: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorSchemeContrast) private var contrast

    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609),
        latitudinalMeters: 5000, longitudinalMeters: 5000
    ))

    private var accentColor: Color { viewModel.isSeller ? .green : .blue }
    private var title: String { viewModel.isSeller ? "Estate Location" : "Sourcing Location" }
    private var locationKind: String { viewModel.isSeller ? "estate" : "sourcing zone" }

    var body: some View {
        List {
            Section {
                ZStack {
                    Map(position: $cameraPosition, interactionModes: []) {
                        MapCircle(center: viewModel.coordinate, radius: 2000)
                            .foregroundStyle(accentColor.opacity(0.25))
                        Marker(viewModel.isSeller ? "Estate" : "Zone",
                               coordinate: viewModel.coordinate)
                            .tint(accentColor)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    // High Contrast: add a visible border around the map
                    .overlay(
                        contrast == .increased
                            ? AnyView(RoundedRectangle(cornerRadius: 10).stroke(accentColor, lineWidth: 2))
                            : AnyView(EmptyView())
                    )
                    Button(action: { viewModel.isMapPresented = true }) { Color.clear }
                }
                .listRowInsets(EdgeInsets())
                .accessibilityElement(children: .ignore)
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel(
                    viewModel.locationName.isEmpty
                        ? "Map preview. No \(locationKind) selected."
                        : "Map preview showing \(viewModel.locationName)."
                )
                .accessibilityHint("Double tap to open the full map and choose a location")
                .overlay(alignment: .topTrailing) {
                    Button(action: { viewModel.isMapPresented = true }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(accentColor)
                            .frame(width: 30, height: 30)
                            .background(Color(UIColor.systemBackground))
                            .clipShape(Circle())
                            .shadow(radius: contrast == .increased ? 0 : 2)
                            // High Contrast: border on expand button
                            .overlay(
                                contrast == .increased
                                    ? AnyView(Circle().stroke(accentColor, lineWidth: 1.5))
                                    : AnyView(EmptyView())
                            )
                    }
                    .padding(10)
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityHidden(true)
                }

                // Selected location row
                // High Contrast: bold the location name for better readability
                HStack {
                    Label("Selected Zone", systemImage: "location.fill")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .accessibilityHidden(true)
                    Spacer()
                    Text(viewModel.locationName.isEmpty ? "Not set" : viewModel.locationName)
                        .font(contrast == .increased ? .subheadline.bold() : .subheadline.bold())
                        .foregroundColor(contrast == .increased ? .primary : .primary)
                        .multilineTextAlignment(.trailing)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Selected location")
                .accessibilityValue(viewModel.locationName.isEmpty ? "Not set" : viewModel.locationName)

                // Change Location button
                // High Contrast: solid background instead of text-only button
                Button(action: { viewModel.isMapPresented = true }) {
                    HStack {
                        Spacer()
                        Label("Change Location", systemImage: "map.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(contrast == .increased ? .white : accentColor)
                        Spacer()
                    }
                    .padding(.vertical, contrast == .increased ? 10 : 0)
                    .background(
                        contrast == .increased
                            ? AnyShapeStyle(accentColor)
                            : AnyShapeStyle(Color.clear)
                    )
                    .cornerRadius(contrast == .increased ? 8 : 0)
                }
                .accessibilityLabel("Change location")
                .accessibilityHint("Opens the full map to pick a new \(locationKind)")

            } header: {
                Text("Location")
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
                    .accessibilityLabel("Save")
                    .accessibilityHint("Saves the selected \(locationKind) location")
            }
        }
        .sheet(isPresented: $viewModel.isMapPresented) {
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
        .onChange(of: viewModel.locationName) { _, _ in
            cameraPosition = .region(MKCoordinateRegion(
                center: viewModel.coordinate,
                latitudinalMeters: 5000, longitudinalMeters: 5000
            ))
        }
        .overlay {
            if viewModel.saveSuccess { saveSuccessOverlay(accentColor: accentColor) }
        }
    }
}

// MARK: - Shared helper row builder
// Dynamic Type: stacks label above input at accessibility sizes
private func editRow<Content: View>(
    icon: String,
    label: String,
    typeSize: DynamicTypeSize,
    @ViewBuilder trailing: () -> Content
) -> some View {
    Group {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .accessibilityHidden(true)
                    Text(label)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                trailing()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 6)
        } else {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .frame(width: 20)
                    .accessibilityHidden(true)
                Text(label)
                    .font(.subheadline)    // Dynamic Type: scales automatically
                    .foregroundColor(.secondary)
                Spacer()
                trailing()
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Shared save success overlay
private func saveSuccessOverlay(accentColor: Color) -> some View {
    VStack(spacing: 16) {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 60))
            .foregroundColor(accentColor)
            .accessibilityHidden(true)
        Text("Saved")
            .font(.title2.bold())          // Dynamic Type: scales automatically
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.ultraThinMaterial)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Saved successfully")
    .accessibilityAddTraits(.isStaticText)
}

#Preview {
    ProfileView()
}
