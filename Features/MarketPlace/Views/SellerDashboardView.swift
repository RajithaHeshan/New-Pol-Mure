
import SwiftUI
import MapKit

struct SellerDashboardView: View {
    @State private var viewModel = SellerDashboardViewModel()
    @State private var navigateToContract: Contract? = nil
    @State private var miniMapCamera: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

              
                    greetingSection

                    HStack(spacing: 16) {
                        NavigationLink(destination: SellerPerformanceView()) {
                            MetricCard(
                                title: "Escrow Pending",
                                amount: viewModel.escrowTotal > 0 ? "Rs \(formatAmount(viewModel.escrowTotal))" : "—",
                                icon: "lock.shield.fill",
                                color: .green
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: SellerPerformanceView()) {
                            MetricCard(
                                title: "Active Offers",
                                amount: viewModel.activeOffersTotal > 0 ? "Rs \(formatAmount(viewModel.activeOffersTotal))" : "—",
                                icon: "chart.line.uptrend.xyaxis",
                                color: .blue
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    
                    //dispute cardmenu

                    if let message = viewModel.urgentContractMessage {
                        UrgentActionBanner(
                            message: message,
                            isDispute: viewModel.disputeReason != nil,
                            disputeReason: viewModel.disputeReason,
                            disputeNotes: viewModel.disputeNotes,
                            disputeCounterOffer: viewModel.disputeCounterOffer
                        ) {
                            navigateToContract = viewModel.urgentContract //navigate to the contract menu
                        }
                        .padding(.horizontal)
                    }

                    Divider().padding(.vertical, 8)

                    SellerFilterChipsView(filters: viewModel.filters, selectedFilter: $viewModel.selectedFilter)

                    // MARK: Recommended Buyers
                    if viewModel.selectedFilter != "Urgent Need" {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recommended Buyers")
                                .font(.title3.bold())
                                .padding(.horizontal)

                            if viewModel.isLoadingBuyers {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                            } else if viewModel.recommendedBuyers.isEmpty {
                                Text("No buyers available yet.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.recommendedBuyers) { buyer in
                                            let locked = viewModel.lockedBuyerIDs.contains(buyer.id)
                                            NavigationLink(destination: LiveOfferView(buyer: buyer)) {
                                                RecommendedBuyerCard(buyer: buyer, highestOffer: viewModel.highestOfferPerBuyer[buyer.id], showUrgentBadge: false, isPitchLocked: locked)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .disabled(locked)
                                            .allowsHitTesting(!locked)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }

                    Divider().padding(.vertical, 8)

                  
                    VStack(spacing: 16) {
                        HStack {
                            Text("Find Buyers Near My Estate")
                                .font(.title3.bold())
                            Spacer()
                        }
                        .padding(.horizontal)

                        VStack(spacing: 12) {
                            Map(position: $miniMapCamera, interactionModes: []) {

                                MapCircle(center: viewModel.searchCenter, radius: viewModel.searchRadius * 1000)
                                    .foregroundStyle(.orange.opacity(0.3))

                                Marker(viewModel.searchText.isEmpty ? "My Estate" : viewModel.searchText, coordinate: viewModel.searchCenter)
                                    .tint(.orange)

                                ForEach(viewModel.buyersInRadius) { buyer in
                                    Annotation(buyer.name, coordinate: buyer.coordinate) {
                                        Image(systemName: "building.2.fill")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Color.orange)
                                            .clipShape(Circle())
                                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                    }
                                }
                            }
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onChange(of: viewModel.searchCenter.latitude) { _, _ in updateMiniMap() }
                            .onChange(of: viewModel.searchCenter.longitude) { _, _ in updateMiniMap() }
                            .onChange(of: viewModel.searchRadius) { _, _ in updateMiniMap() }
                            .overlay(alignment: .topTrailing) {
                                Button(action: { viewModel.isFullScreenMapPresented = true }) {
                                    Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                                        .font(.caption.bold())
                                        .padding(8)
                                        .background(.thickMaterial)
                                        .clipShape(Circle())
                                        .shadow(radius: 2)
                                }
                                .padding(8)
                            }

                            HStack {
                                Text("Delivery Radius:")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(viewModel.searchRadius)) km")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }
                            Slider(value: $viewModel.searchRadius, in: 1...200, step: 5)
                                .tint(.orange)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

                    Divider().padding(.vertical, 8)

                 
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(sectionTitle)
                                .font(.title3.bold())
                            Spacer()
                            Text("\(viewModel.selectedFilter == "Urgent Need" ? viewModel.urgentPosts.count : viewModel.buyersInRadius.count) Found")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        if viewModel.selectedFilter == "Urgent Need" {
                            if viewModel.urgentPosts.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "tray.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text("No urgent buyer posts yet.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 40)
                                .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(viewModel.urgentPosts) { post in
                                        UrgentPostCard(
                                            post: post,
                                            buyer: viewModel.buyer(for: post),
                                            highestOffer: viewModel.highestUrgentPitchPerBuyer[post.buyerID],
                                            isPitchLocked: viewModel.lockedBuyerIDs.contains(post.buyerID)
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            if viewModel.isLoadingBuyers {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            } else if viewModel.buyersInRadius.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "tray.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text(viewModel.selectedFilter == "High Capacity" ? "No high capacity buyers in this radius." : "No buyers inside this radius.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 40)
                                .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(viewModel.buyersInRadius) { buyer in
                                        BuyerRowCard(
                                            buyer: buyer,
                                            highestOffer: viewModel.highestOfferPerBuyer[buyer.id],
                                            isPitchLocked: viewModel.lockedBuyerIDs.contains(buyer.id)
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .onAppear {
                viewModel.onAppear()
                updateMiniMap()
            }
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search a town e.g. Kandy...")
            .overlay(alignment: .top) {
                
                if viewModel.isSearchingLocation {
                    HStack(spacing: 8) {
                        ProgressView().scaleEffect(0.8)
                        Text("Finding location...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(.thinMaterial)
                    .cornerRadius(20)
                    .padding(.top, 8)
                }
            }

           
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {

                       
                        Button(action: { viewModel.showNotifications = true }) {
                            Image(systemName: viewModel.unreadNotificationCount > 0 ? "bell.badge.fill" : "bell.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                        }

                       
                        Button(action: { viewModel.showProfile = true }) {
                            Image(viewModel.profileImageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        }
                    }
                }
            }

            .sheet(isPresented: $viewModel.showProfile) {
                ProfileView()
            }
            .sheet(isPresented: $viewModel.showNotifications) {
                NotificationsView(
                    ownerID: viewModel.currentUserID,
                    accentColor: .green,
                    onDismiss: { viewModel.showNotifications = false }
                )
            }
            .sheet(isPresented: $viewModel.isFullScreenMapPresented) {
                SellerFullScreenLocationPicker(searchCenter: $viewModel.searchCenter, searchRadius: $viewModel.searchRadius, buyers: viewModel.allBuyers)
            }
            .navigationDestination(item: $navigateToContract) { contract in
                SellerContractView(contract: contract)
            }
        }
    }
}

extension SellerDashboardView {
    var sectionTitle: String {
        switch viewModel.selectedFilter {
        case "Urgent Need":    return "Urgent Posts"
        case "High Capacity":  return "High Capacity Buyers"
        case "Nearest to Me":  return "Nearest Buyers"
        default:               return "Buyers in Radius"
        }
    }

    func updateMiniMap() {
        let span = viewModel.searchRadius * 2500
        miniMapCamera = .region(MKCoordinateRegion(
            center: viewModel.searchCenter,
            latitudinalMeters: span,
            longitudinalMeters: span
        ))
    }

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
}

private func formatAmount(_ value: Double) -> String {
    if value >= 1_000_000 { return String(format: "%.1fM", value / 1_000_000) }
    if value >= 1_000     { return String(format: "%.0fK", value / 1_000) }
    return String(format: "%.0f", value)
}

#Preview {
    SellerDashboardView()
}
