import SwiftUI
import MapKit

struct HarvestCreatorView: View {
    @State private var viewModel = HarvestCreatorViewModel()
    @State private var showCreateModal = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                        Text("Manage your active harvest listings here.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    if viewModel.isLoadingHarvests {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                    } else if viewModel.myHarvests.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "basket.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No Active Listings")
                                .font(.title3.bold())
                            Text("List your harvest lot and let buyers bid on it directly.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)

                            Button(action: { showCreateModal = true }) {
                                Text("Create New Harvest")
                                    .font(.headline)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 10)
                        }
                        .padding(.vertical, 60)
                    } else {
                        ForEach(viewModel.myHarvests) { harvest in
                            HarvestLotCard(harvest: harvest) {
                                viewModel.deleteHarvest(harvest)
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("My Harvests")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateModal = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $showCreateModal) {
                HarvestCreateModalView(viewModel: viewModel)
                    .presentationDetents([.large])
            }
        }
    }
}

// MARK: - Harvest Lot Card

struct HarvestLotCard: View {
    let harvest: HarvestLotItem
    let onDelete: () -> Void

    var statusColor: Color {
        let daysLeft = harvest.endDate.timeIntervalSinceNow / 86400
        return daysLeft < 1 ? .red : .orange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACTIVE LISTING")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            HStack(spacing: 12) {
                Image("Gemini_Generated_Image_bvc5lzbvc5lzbvc5")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 6) {
                    if !harvest.propertyName.isEmpty {
                        Text(harvest.propertyName)
                            .font(.headline)
                    }
                    Text("\(harvest.quantity) Nuts")
                        .font(.title3.bold())
                    Text(harvest.qualityGrade)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption2)
                        Text(harvest.locationName)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Rs \(String(format: "%.0f", harvest.currentBid))")
                        .font(.headline.bold())
                        .foregroundColor(.orange)
                    Text("Current Bid")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(harvest.endDate, style: .relative)
                        .font(.caption.bold())
                        .foregroundColor(statusColor)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Create Modal

struct HarvestCreateModalView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var viewModel: HarvestCreatorViewModel

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Harvest Details
                Section {
                    TextField("Property Name", text: $viewModel.propertyName)
                        .textInputAutocapitalization(.words)

                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("e.g. 10000", text: $viewModel.quantity)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("Nuts").foregroundColor(.secondary)
                    }

                    Picker("Quality Grade", selection: $viewModel.qualityGrade) {
                        ForEach(viewModel.qualityOptions, id: \.self) { Text($0).tag($0) }
                    }

                    DatePicker("Harvest Date", selection: $viewModel.harvestDate, displayedComponents: .date)

                    HStack {
                        Text("Starting Price")
                        Spacer()
                        Text("Rs").foregroundColor(.secondary)
                        TextField("0.00", text: $viewModel.startingPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                } header: {
                    Text("Harvest Details")
                }

             
                if viewModel.isReadyForSuggestion {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "sparkles").foregroundColor(.purple)
                                Text("Market Suggestion")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.purple)
                            }
                            Text("Suggested price for \(viewModel.qualityGrade): **Rs \(viewModel.suggestedPrice, specifier: "%.2f")**")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button(action: { viewModel.applySuggestion() }) {
                                Text("Apply Suggestion")
                                    .font(.caption.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.purple)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 4)
                    }
                }

                // MARK: - Location Privacy
                Section {
                    ZStack {
                        Map(position: $viewModel.inlineCameraPosition, interactionModes: []) {
                            MapCircle(center: viewModel.estateLocation, radius: 2000)
                                .foregroundStyle(.orange.opacity(0.3))
                            Marker("Estate", coordinate: viewModel.estateLocation)
                                .tint(.orange)
                        }
                        .frame(height: 140)

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
                        Text(viewModel.locationName.isEmpty ? "Not set" : viewModel.locationName)
                            .font(.subheadline.bold())
                            .foregroundColor(viewModel.locationName.isEmpty ? .secondary : .primary)
                    }

                    Text("Buyers see only a 5km fuzzy zone until Escrow is secured.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Location Privacy")
                }

                // MARK: - Submit
                Section {
                    Button(action: {
                        viewModel.launchAuction(onSuccess: { dismiss() })
                    }) {
                        if viewModel.isLaunching {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("Launch Auction")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(viewModel.isLaunching)
                    .listRowBackground(Color.orange)
                }
            }
            .navigationTitle("New Harvest Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.isFullScreenMapPresented) {
                EstateLocationMapScreen(
                    estateLocation: $viewModel.estateLocation,
                    locationName: $viewModel.locationName
                )
            }
            .onChange(of: viewModel.locationName) { _, _ in
                viewModel.inlineCameraPosition = .region(MKCoordinateRegion(
                    center: viewModel.estateLocation,
                    latitudinalMeters: 5000,
                    longitudinalMeters: 5000
                ))
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.launchError != nil },
                set: { if !$0 { viewModel.launchError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.launchError ?? "")
            }
        }
    }
}

#Preview {
    HarvestCreatorView()
}
