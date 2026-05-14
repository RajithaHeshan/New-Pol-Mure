import SwiftUI
import MapKit

struct DiscoveryDashboardView: View {
    @State private var viewModel = DiscoveryDashboardViewModel()
    @State private var mapCameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    greetingSection
                    spendBannerSection
                    FilterChipsView(filters: viewModel.filters, selectedFilter: $viewModel.selectedFilter)
                    recommendedSection
                    Divider().padding(.vertical, 8)
                    mapRadiusSection
                    Divider().padding(.vertical, 8)
                    sellersInRadiusSection
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Marketplace")
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search a town e.g. Kurunegala...")
            .overlay(alignment: .top) { locationSearchingOverlay }
            .onAppear {
                viewModel.fetchUserProfile()
                viewModel.attachMonthlySpendListener()
            }
            .toolbar { toolbarContent }
            .sheet(isPresented: $viewModel.showProfile) { profileSheet }
            .sheet(isPresented: $viewModel.showNotifications) { notificationsSheet }
            .sheet(isPresented: $viewModel.isFullScreenMapPresented) {
                FullScreenLocationPicker(searchCenter: $viewModel.searchCenter, searchRadius: $viewModel.searchRadius, sellers: viewModel.allSellers)
            }
            .navigationDestination(for: String.self) { harvestID in
                if let harvest = viewModel.activeHarvests.first(where: { $0.id == harvestID }) {
                    LiveBiddingView(lot: harvest.toHarvestLot())
                }
            }
            .navigationDestination(for: SellerLocation.self) { seller in  //navigate LiveBiddingView
                LiveBiddingView(lot: seller.toHarvestLot(currentBid: viewModel.highestBid(for: seller)))
            }
        }
    }




  
    private var spendBannerSection: some View {
        NavigationLink(destination: BuyerPerformanceView()) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Spend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.monthlySpend > 0 ? "Rs \(viewModel.monthlySpend, specifier: "%.0f")" : "Rs 0")
                        .font(.headline.bold())
                        .foregroundColor(.primary)
                }
                Spacer()
                HStack {
                    Text("View Performance").font(.caption.bold())
                    Image(systemName: "chevron.right").font(.caption)
                }
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 10)
        }
        .buttonStyle(PlainButtonStyle())
    }

    //  Greeting
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(greetingText)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(viewModel.fullName.isEmpty ? "Welcome!" : "Hi, \(viewModel.fullName) 👋")
                .font(.title2.bold())
                .foregroundColor(.primary)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default:      return "Good Night"
        }
    }

    // Recommended
    private var recommendedSection: some View {
        VStack(alignment: .leading) {
            Text("Recommended For You")
                .font(.title3.bold())
                .padding(.horizontal)

            let isLoading = viewModel.isLoadingSellers || viewModel.isLoadingHarvests
            let hasContent = !viewModel.recommendedSellers.isEmpty || !viewModel.mlRecommendedHarvests.isEmpty

            if isLoading {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 20)
            } else if !hasContent {
                Text("No sellers available yet.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .padding(.horizontal).padding(.top, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        // Registered sellers
                        ForEach(viewModel.recommendedSellers) { seller in
                            RecommendedSellerCard(
                                seller: seller,
                                currentHighestBid: viewModel.highestBid(for: seller),
                                isBidLocked: viewModel.lockedSellerIDs.contains(seller.id)
                                          || viewModel.lockedHarvestIDs.contains(seller.id)
                            )
                        }
                        // Harvest lots created by sellers
                        ForEach(viewModel.mlRecommendedHarvests) { harvest in
                            RecommendedHarvestCard(
                                harvest: harvest,
                                currentHighestBid: viewModel.highestBid(for: harvest),
                                sellerRating: viewModel.sellerRatings[harvest.sellerID]?.0 ?? 0.0,
                                sellerRatingCount: viewModel.sellerRatings[harvest.sellerID]?.1 ?? 0,
                                isBidLocked: viewModel.lockedHarvestIDs.contains(harvest.id)
                                          || viewModel.lockedSellerIDs.contains(harvest.sellerID)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    //  Map Radius
    private var mapRadiusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Find Sellers Near Me").font(.title3.bold())
                Spacer()
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                Map(position: $mapCameraPosition, interactionModes: []) {
                    MapCircle(center: viewModel.searchCenter, radius: viewModel.searchRadius * 1000)
                        .foregroundStyle(.blue.opacity(0.3))
                    Marker("Search Zone", coordinate: viewModel.searchCenter).tint(.blue)
                    if let gps = viewModel.deviceLocation {
                        Annotation("You", coordinate: gps) {
                            ZStack {
                                Circle().fill(Color.blue.opacity(0.2)).frame(width: 28, height: 28)
                                Circle().fill(Color.blue).frame(width: 14, height: 14)
                                Circle().stroke(Color.white, lineWidth: 2).frame(width: 14, height: 14)
                            }
                        }
                    }
                    ForEach(viewModel.sellersInRadius) { seller in
                        Annotation(seller.sellerName, coordinate: seller.coordinate) {
                            Image(systemName: "leaf.fill")
                                .font(.headline).foregroundColor(.white)
                                .padding(8).background(Color.green).clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    ForEach(viewModel.harvestsInRadius) { harvest in
                        Annotation(harvest.propertyName.isEmpty ? harvest.sellerName : harvest.propertyName,
                                   coordinate: CLLocationCoordinate2D(latitude: harvest.latitude, longitude: harvest.longitude)) {
                            Image(systemName: "basket.fill")
                                .font(.headline).foregroundColor(.white)
                                .padding(8).background(Color.orange).clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topTrailing) {
                    Button(action: { viewModel.isFullScreenMapPresented = true }) {
                        Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                            .font(.caption.bold()).padding(8)
                            .background(.thickMaterial).clipShape(Circle()).shadow(radius: 2)
                    }
                    .padding(8)
                }
                .onChange(of: viewModel.searchCenter.latitude) { _, _ in
                    mapCameraPosition = .region(MKCoordinateRegion(
                        center: viewModel.searchCenter,
                        latitudinalMeters: viewModel.searchRadius * 2500,
                        longitudinalMeters: viewModel.searchRadius * 2500
                    ))
                }
                .onChange(of: viewModel.searchRadius) { _, _ in
                    mapCameraPosition = .region(MKCoordinateRegion(
                        center: viewModel.searchCenter,
                        latitudinalMeters: viewModel.searchRadius * 2500,
                        longitudinalMeters: viewModel.searchRadius * 2500
                    ))
                }
                .onAppear {
                    mapCameraPosition = .region(MKCoordinateRegion(
                        center: viewModel.searchCenter,
                        latitudinalMeters: viewModel.searchRadius * 2500,
                        longitudinalMeters: viewModel.searchRadius * 2500
                    ))
                }

                HStack {
                    Text("Radius:").font(.subheadline)
                    Spacer()
                    Text("\(Int(viewModel.searchRadius)) km").font(.headline).foregroundColor(.blue)
                }
                Slider(value: $viewModel.searchRadius, in: 1...200, step: 5).tint(.blue)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }

    // MARK: - Sellers in Radius (includes registered sellers + their harvest lots)
    private var sellersInRadiusSection: some View {
        let totalCount = viewModel.sellersInRadius.count + viewModel.harvestsInRadius.count
        let isLoading  = viewModel.isLoadingSellers || viewModel.isLoadingHarvests

        let sectionTitle: String = {
            switch viewModel.selectedFilter {
            case "High Volume":   return "High Volume Sellers"
            case "Ending Soon":   return "Ending Soon"
            case "Nearest to Me": return "Nearest Sellers"
            default:              return "Sellers in Radius"
            }
        }()

        let emptyMessage: String = {
            switch viewModel.selectedFilter {
            case "High Volume":   return "No high-volume sellers (≥5000 nuts) in this radius."
            case "Ending Soon":   return "No harvests ending within 2 days in this radius."
            case "Nearest to Me": return "No sellers found in this radius."
            default:              return "No sellers inside this radius."
            }
        }()

        return VStack(alignment: .leading) {
            HStack {
                Text(sectionTitle).font(.title3.bold())
                Spacer()
                Text("\(totalCount) Found")
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(.horizontal)

            if isLoading {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 40)
            } else if totalCount == 0 {
                VStack(spacing: 8) {
                    Image(systemName: "tray.fill").font(.largeTitle).foregroundColor(.secondary)
                    Text(emptyMessage).font(.subheadline).foregroundColor(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal, 32)
                }
                .padding(.vertical, 40).frame(maxWidth: .infinity, alignment: .center)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.sellersInRadius) { seller in
                        SellerRow(
                            seller: seller,
                            currentHighestBid: viewModel.highestBid(for: seller),
                            isBidLocked: viewModel.lockedSellerIDs.contains(seller.id)
                                      || viewModel.lockedHarvestIDs.contains(seller.id)
                        )
                    }
                    ForEach(viewModel.harvestsInRadius) { harvest in
                        let harvestLocked = viewModel.lockedHarvestIDs.contains(harvest.id)
                                        || viewModel.lockedSellerIDs.contains(harvest.sellerID)
                        if harvestLocked {
                            HarvestRowCard(
                                harvest: harvest,
                                currentHighestBid: viewModel.highestBid(for: harvest),
                                sellerRating: viewModel.sellerRatings[harvest.sellerID]?.0 ?? 0.0,
                                sellerRatingCount: viewModel.sellerRatings[harvest.sellerID]?.1 ?? 0,
                                isBidLocked: true
                            )
                        } else {
                            NavigationLink(value: harvest.id) {
                                HarvestRowCard(
                                    harvest: harvest,
                                    currentHighestBid: viewModel.highestBid(for: harvest),
                                    sellerRating: viewModel.sellerRatings[harvest.sellerID]?.0 ?? 0.0,
                                    sellerRatingCount: viewModel.sellerRatings[harvest.sellerID]?.1 ?? 0,
                                    isBidLocked: false
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 30)
    }

    // MARK: - Overlays / Toolbar / Sheets
    @ViewBuilder
    private var locationSearchingOverlay: some View {
        if viewModel.isSearchingLocation {
            HStack(spacing: 8) {
                ProgressView().scaleEffect(0.8)
                Text("Finding location...").font(.caption).foregroundColor(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 6)
            .background(.thinMaterial).cornerRadius(20).padding(.top, 8)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent { //profile notifcation iocn
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 16) {
                Button(action: { viewModel.showNotifications = true }) {
                    Image(systemName: viewModel.unreadNotificationCount > 0 ? "bell.badge.fill" : "bell.fill")
                        .font(.title3).foregroundColor(.blue)
                }
                Button(action: { viewModel.showProfile = true }) {
                    Image(viewModel.profileImageName)
                        .resizable().scaledToFill()
                        .frame(width: 32, height: 32).clipShape(Circle())
                }
            }
        }
    }

    private var profileSheet: some View {
        ProfileView()
    }

    private var notificationsSheet: some View {
        NotificationsView(
            ownerID: viewModel.currentUserID,
            accentColor: .blue,
            onDismiss: { viewModel.showNotifications = false }
        )
    }
}

#Preview {
    DiscoveryDashboardView()
}
