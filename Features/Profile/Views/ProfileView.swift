import SwiftUI
import MapKit

// Apple HIG minimum tap target: 44×44 points
private let kMinTapSize: CGFloat = 44

// MARK: - Account Root
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var viewModel = ProfileViewModel()

    private var accentColor: Color { viewModel.isSeller ? .green : .blue }
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
                        // Minimum tap target: ensure Done button is at least 44pt tall
                        .frame(minWidth: kMinTapSize, minHeight: kMinTapSize)
                        .contentShape(Rectangle())
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
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Main Account List
    private var accountList: some View {
        List {
            // MARK: Avatar Header
            Section {
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
                // Each NavigationLink row has .frame(minHeight: 44) via accountRow padding
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
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.red)
                    // Minimum tap target: full-width, at least 44pt tall
                    .frame(maxWidth: .infinity, minHeight: kMinTapSize, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Sign Out")
                .accessibilityHint("Signs you out of your account")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Avatar Image
    private var avatarImage: some View {
        Image(viewModel.profileImageName.isEmpty ? "person.circle" : viewModel.profileImageName)
            .resizable()
            .scaledToFill()
            .frame(width: 72, height: 72)
            .clipShape(Circle())
            .overlay(Circle().stroke(accentColor, lineWidth: avatarBorderWidth))
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
                .font(.title3.bold())
                .multilineTextAlignment(.center)

            Text(viewModel.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text(viewModel.isSeller ? "Seller Account" : "Buyer Account")
                .font(.caption.bold())
                .foregroundColor(contrast == .increased ? .white : accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    contrast == .increased
                        ? AnyShapeStyle(accentColor)
                        : AnyShapeStyle(accentColor.opacity(0.1))
                )
                .clipShape(Capsule())
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
    // minHeight: 44 ensures every row meets the HIG minimum tap target
    private func accountRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    iconBadge(icon: icon, iconColor: iconColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.body)
                            .foregroundColor(.primary)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: kMinTapSize, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.vertical, 6)
            } else {
                HStack(spacing: 14) {
                    iconBadge(icon: icon, iconColor: iconColor)
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
                .frame(maxWidth: .infinity, minHeight: kMinTapSize, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.vertical, 4)
            }
        }
    }

    private func iconBadge(icon: String, iconColor: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 30, height: 30)
            .background(iconColor)
            .cornerRadius(7)
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
                editRow(icon: "person.fill", label: "Full Name", typeSize: typeSize) {
                    TextField("Enter your name", text: $viewModel.fullName)
                        .multilineTextAlignment(typeSize.isAccessibilitySize ? .leading : .trailing)
                        .textContentType(.name)
                        // Minimum tap target on the text field itself
                        .frame(minHeight: kMinTapSize)
                        .accessibilityLabel("Full Name")
                        .accessibilityValue(viewModel.fullName.isEmpty ? "Not set" : viewModel.fullName)
                        .accessibilityHint("Enter your full name")
                }

                editRow(icon: "phone.fill", label: "Phone", typeSize: typeSize) {
                    TextField("Phone number", text: $viewModel.phone)
                        .multilineTextAlignment(typeSize.isAccessibilitySize ? .leading : .trailing)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .frame(minHeight: kMinTapSize)
                        .accessibilityLabel("Phone number")
                        .accessibilityValue(viewModel.phone.isEmpty ? "Not set" : viewModel.phone)
                        .accessibilityHint("Enter your contact phone number")
                }

                // Email — read only
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
                // Minimum tap target: 44pt tall even though it is read-only
                .frame(minHeight: kMinTapSize)
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
                    .font(.footnote)
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
                // Minimum tap target on Save button
                .frame(minWidth: kMinTapSize, minHeight: kMinTapSize)
                .contentShape(Rectangle())
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
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Yield / Harvest")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack {
                            TextField("e.g. 10000", text: $viewModel.typicalYield)
                                .keyboardType(.numberPad)
                                .foregroundColor(.green)
                                .frame(minHeight: kMinTapSize)
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
                            .frame(width: 80, height: kMinTapSize)
                            .accessibilityLabel("Typical yield")
                            .accessibilityValue(viewModel.typicalYield.isEmpty ? "Not set" : "\(viewModel.typicalYield) nuts")
                            .accessibilityHint("Enter the number of coconuts you typically harvest")
                        Text("Nuts").foregroundColor(.secondary).font(.subheadline)
                            .accessibilityHidden(true)
                    }
                    .frame(minHeight: kMinTapSize)
                }

                DatePicker(
                    "Next Harvest Date",
                    selection: $viewModel.nextHarvestDate,
                    displayedComponents: .date
                )
                .tint(.green)
                // DatePicker is already 44pt tall — ensure it with minHeight
                .frame(minHeight: kMinTapSize)
                .accessibilityLabel("Next harvest date")
                .accessibilityValue(viewModel.nextHarvestDate.formatted(date: .abbreviated, time: .omitted))
                .accessibilityHint("Select the expected date of your next coconut harvest")

                Picker("Certification", selection: $viewModel.certificationLevel) {
                    ForEach(viewModel.certificationLevels, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
                .tint(.green)
                // Picker row minimum tap target
                .frame(minHeight: kMinTapSize)
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
                    .frame(minWidth: kMinTapSize, minHeight: kMinTapSize)
                    .contentShape(Rectangle())
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
                .frame(minHeight: kMinTapSize)
                .accessibilityLabel("Business type")
                .accessibilityValue(viewModel.businessType.isEmpty ? "Not selected" : viewModel.businessType)
                .accessibilityHint("Select the category that best describes your business")

                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Typical Volume")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack {
                            TextField("e.g. 5000", text: $viewModel.typicalVolume)
                                .keyboardType(.numberPad)
                                .foregroundColor(.blue)
                                .frame(minHeight: kMinTapSize)
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
                            .frame(width: 80, height: kMinTapSize)
                            .accessibilityLabel("Typical purchase volume")
                            .accessibilityValue(viewModel.typicalVolume.isEmpty ? "Not set" : "\(viewModel.typicalVolume) nuts")
                            .accessibilityHint("Enter the number of coconuts you typically buy per order")
                        Text("Nuts").foregroundColor(.secondary).font(.subheadline)
                            .accessibilityHidden(true)
                    }
                    .frame(minHeight: kMinTapSize)
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
                    .frame(minWidth: kMinTapSize, minHeight: kMinTapSize)
                    .contentShape(Rectangle())
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
                // Map preview
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
                    .overlay(
                        contrast == .increased
                            ? AnyView(RoundedRectangle(cornerRadius: 10).stroke(accentColor, lineWidth: 2))
                            : AnyView(EmptyView())
                    )
                    // Transparent tap target — minimum 44pt enforced by the 180pt frame
                    Button(action: { viewModel.isMapPresented = true }) { Color.clear }
                        .contentShape(Rectangle())
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
                            // Minimum tap target: 44×44 for the expand button
                            .frame(width: kMinTapSize, height: kMinTapSize)
                            .background(Color(UIColor.systemBackground))
                            .clipShape(Circle())
                            .shadow(radius: contrast == .increased ? 0 : 2)
                            .overlay(
                                contrast == .increased
                                    ? AnyView(Circle().stroke(accentColor, lineWidth: 1.5))
                                    : AnyView(EmptyView())
                            )
                    }
                    .contentShape(Circle())
                    .padding(6)
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityHidden(true)
                }

                // Selected location display
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
                .frame(minHeight: kMinTapSize)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Selected location")
                .accessibilityValue(viewModel.locationName.isEmpty ? "Not set" : viewModel.locationName)

                // Change Location button — minimum 44pt tall, full width tappable
                Button(action: { viewModel.isMapPresented = true }) {
                    HStack {
                        Spacer()
                        Label("Change Location", systemImage: "map.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(contrast == .increased ? .white : accentColor)
                        Spacer()
                    }
                    // Minimum tap target: full width, at least 44pt tall
                    .frame(maxWidth: .infinity, minHeight: kMinTapSize)
                    .background(
                        contrast == .increased
                            ? AnyShapeStyle(accentColor)
                            : AnyShapeStyle(Color.clear)
                    )
                    .cornerRadius(contrast == .increased ? 8 : 0)
                }
                .contentShape(Rectangle())
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
                    .frame(minWidth: kMinTapSize, minHeight: kMinTapSize)
                    .contentShape(Rectangle())
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
            // Minimum tap target for the whole stacked row
            .frame(maxWidth: .infinity, minHeight: kMinTapSize, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.vertical, 6)
        } else {
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
            // Minimum tap target: full width, at least 44pt tall
            .frame(maxWidth: .infinity, minHeight: kMinTapSize)
            .contentShape(Rectangle())
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
            .font(.title2.bold())
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
