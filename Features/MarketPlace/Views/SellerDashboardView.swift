
import SwiftUI
import MapKit

struct SellerDashboardView: View {
    @State private var viewModel = SellerDashboardViewModel()
    @State private var navigateToContract: Contract? = nil

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

                    if let message = viewModel.urgentContractMessage {
                        UrgentActionBanner(message: message) {
                            navigateToContract = viewModel.urgentContract
                        }
                        .padding(.horizontal)
                    }

                    Divider().padding(.vertical, 8)

                    SellerFilterChipsView(filters: viewModel.filters, selectedFilter: $viewModel.selectedFilter)

                    // MARK: Recommended Buyers
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
                                        NavigationLink(destination: LiveOfferView(buyer: buyer)) {
                                            RecommendedBuyerCard(buyer: buyer, highestOffer: viewModel.highestOfferPerBuyer[buyer.id], showUrgentBadge: viewModel.selectedFilter == "Urgent Need")
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
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
                            Map(position: .constant(.region(MKCoordinateRegion(center: viewModel.searchCenter, latitudinalMeters: viewModel.searchRadius * 2500, longitudinalMeters: viewModel.searchRadius * 2500))), interactionModes: []) {

                                MapCircle(center: viewModel.searchCenter, radius: viewModel.searchRadius * 1000)
                                    .foregroundStyle(.orange.opacity(0.3))

                                Marker("My Estate", coordinate: viewModel.searchCenter)
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
                            Text(viewModel.selectedFilter == "Urgent Need" ? "Urgent Posts" : "Buyers in Radius")
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
                                        UrgentPostCard(post: post, buyer: viewModel.buyer(for: post))
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
                                    Text("No buyers inside this radius.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 40)
                                .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(viewModel.buyersInRadius) { buyer in
                                        BuyerRowCard(buyer: buyer, highestOffer: viewModel.highestOfferPerBuyer[buyer.id])
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
            .onAppear { viewModel.onAppear() }
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
                NavigationStack {
                    Text("Notifications Placeholder")
                        .navigationTitle("Notifications")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { viewModel.showNotifications = false } } }
                }
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
