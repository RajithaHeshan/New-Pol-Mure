import SwiftUI
import MapKit

struct DiscoveryDashboardView: View {
    @State private var viewModel = DiscoveryDashboardViewModel()

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
            .onAppear { viewModel.fetchUserProfile() }
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
            .navigationDestination(for: SellerLocation.self) { seller in
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

    // MARK: - Greeting
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

    // MARK: - Recommended
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
                                currentHighestBid: viewModel.highestBid(for: seller)
                            )
                        }
                        // Harvest lots created by sellers
                        ForEach(viewModel.mlRecommendedHarvests) { harvest in
                            RecommendedHarvestCard(
                                harvest: harvest,
                                currentHighestBid: viewModel.highestBid(for: harvest),
                                sellerRating: viewModel.sellerRatings[harvest.sellerID]?.0 ?? 0.0,
                                sellerRatingCount: viewModel.sellerRatings[harvest.sellerID]?.1 ?? 0
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Map Radius
    private var mapRadiusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Find Sellers Near Me").font(.title3.bold())
                Spacer()
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                Map(position: .constant(.region(MKCoordinateRegion(
                    center: viewModel.searchCenter,
                    latitudinalMeters: viewModel.searchRadius * 2500,
                    longitudinalMeters: viewModel.searchRadius * 2500
                ))), interactionModes: []) {
                    MapCircle(center: viewModel.searchCenter, radius: viewModel.searchRadius * 1000)
                        .foregroundStyle(.blue.opacity(0.3))
                    Marker("Search Zone", coordinate: viewModel.searchCenter).tint(.blue)
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
                            Image(systemName: "leaf.fill")
                                .font(.headline).foregroundColor(.white)
                                .padding(8).background(Color.green).clipShape(Circle())
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
        let isLoading = viewModel.isLoadingSellers || viewModel.isLoadingHarvests
        return VStack(alignment: .leading) {
            HStack {
                Text("Sellers in Radius").font(.title3.bold())
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
                    Text("No sellers inside this radius.").font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.vertical, 40).frame(maxWidth: .infinity, alignment: .center)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.sellersInRadius) { seller in
                        SellerRow(seller: seller, currentHighestBid: viewModel.highestBid(for: seller))
                    }
                    ForEach(viewModel.harvestsInRadius) { harvest in
                        NavigationLink(value: harvest.id) {
                            HarvestRowCard(
                                harvest: harvest,
                                currentHighestBid: viewModel.highestBid(for: harvest),
                                sellerRating: viewModel.sellerRatings[harvest.sellerID]?.0 ?? 0.0,
                                sellerRatingCount: viewModel.sellerRatings[harvest.sellerID]?.1 ?? 0
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
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
    private var toolbarContent: some ToolbarContent {
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
