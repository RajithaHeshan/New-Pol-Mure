import SwiftUI
import MapKit

struct DiscoveryDashboardView: View {
    @State private var viewModel = DiscoveryDashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
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

    // MARK: - Spend Banner
    private var spendBannerSection: some View {
        NavigationLink(destination: BuyerPerformanceView()) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Spend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Rs 145,000")
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

    // MARK: - Recommended
    private var recommendedSection: some View {
        VStack(alignment: .leading) {
            Text("Recommended For You")
                .font(.title3.bold())
                .padding(.horizontal)

            if viewModel.isLoadingSellers {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 20)
            } else if viewModel.recommendedSellers.isEmpty {
                Text("No sellers available yet.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .padding(.horizontal).padding(.top, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.recommendedSellers) { seller in
                            RecommendedSellerCard(seller: seller, currentHighestBid: viewModel.highestBid(for: seller))
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
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "gearshape.fill").font(.system(size: 60)).foregroundColor(.gray)
                Text("Developer Options").font(.title2.bold())
                Text("Use these tools during testing to clear your cache and database connections.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
                Button(action: {
                    AuthManager.shared.signOut()
                    viewModel.showProfile = false
                }) {
                    Text("Log Out (Clear Session)")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.red).cornerRadius(12)
                }
                .padding(.horizontal, 24).padding(.top, 20)
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Profile").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { viewModel.showProfile = false } } }
        }
    }

    private var notificationsSheet: some View {
        NavigationStack {
            Text("Notifications Placeholder")
                .navigationTitle("Notifications").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { viewModel.showNotifications = false } } }
        }
    }
}

#Preview {
    DiscoveryDashboardView()
}
