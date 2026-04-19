//import SwiftUI
//import MapKit
//
//struct DiscoveryDashboardView: View {
//    @State private var viewModel = DiscoveryDashboardViewModel()
//
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//
//                 
//                    NavigationLink(destination: BuyerPerformanceView()) {
//                        HStack {
//                            VStack(alignment: .leading, spacing: 4) {
//                            Text("Monthly Spend")
//                                    .font(.caption)
//                                    .foregroundColor(.secondary)
//                                Text("Rs 145,000")
//                                    .font(.headline.bold())
//                                    .foregroundColor(.primary)
//                            }
//                            Spacer()
//                            HStack {
//                                Text("View Performance")
//                                    .font(.caption.bold())
//                                Image(systemName: "chevron.right")
//                                    .font(.caption)
//                            }
//                            .foregroundColor(.blue)
//                        }
//                        .padding()
//                        .background(Color(UIColor.secondarySystemBackground))
//                        .cornerRadius(12)
//                        .padding(.horizontal)
//                        .padding(.top, 10)
//                    }
//                    .buttonStyle(PlainButtonStyle())
//
//                    FilterChipsView(filters: viewModel.filters, selectedFilter: $viewModel.selectedFilter)
//
//                  
//                    VStack(alignment: .leading) {
//                        Text("Recommended For You")
//                            .font(.title3.bold())
//                            .padding(.horizontal)
//
//                        if viewModel.isLoadingSellers {
//                            ProgressView()
//                                .frame(maxWidth: .infinity)
//                                .padding(.vertical, 20)
//                        } else if viewModel.recommendedSellers.isEmpty {
//                            Text("No sellers available yet.")
//                                .font(.subheadline)
//                                .foregroundColor(.secondary)
//                                .padding(.horizontal)
//                                .padding(.top, 8)
//                        } else {
//                            ScrollView(.horizontal, showsIndicators: false) {
//                                HStack(spacing: 16) {
//                                    ForEach(viewModel.recommendedSellers) { seller in
//                                        RecommendedSellerCard(seller: seller)
//                                    }
//                                }
//                                .padding(.horizontal)
//                            }
//                        }
//                    }
//
//                    Divider().padding(.vertical, 8)
//
//                  
//                    VStack(spacing: 16) {
//                        HStack {
//                            Text("Find Sellers Near Me")
//                                .font(.title3.bold())
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//
//                        VStack(spacing: 12) {
//                            Map(position: .constant(.region(MKCoordinateRegion(center: viewModel.searchCenter, latitudinalMeters: viewModel.searchRadius * 2500, longitudinalMeters: viewModel.searchRadius * 2500))), interactionModes: []) {
//
//                                MapCircle(center: viewModel.searchCenter, radius: viewModel.searchRadius * 1000)
//                                    .foregroundStyle(.blue.opacity(0.3))
//
//                                Marker("Search Zone", coordinate: viewModel.searchCenter)
//                                    .tint(.blue)
//
//                                ForEach(viewModel.sellersInRadius) { seller in
//                                    Annotation(seller.sellerName, coordinate: seller.coordinate) {
//                                        VStack {
//                                            Image(systemName: "leaf.fill")
//                                                .font(.headline)
//                                                .foregroundColor(.white)
//                                                .padding(8)
//                                                .background(Color.green)
//                                                .clipShape(Circle())
//                                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
//                                        }
//                                    }
//                                }
//                            }
//                            .frame(height: 140)
//                            .clipShape(RoundedRectangle(cornerRadius: 12))
//                            .overlay(alignment: .topTrailing) {
//                                Button(action: { viewModel.isFullScreenMapPresented = true }) {
//                                    Image(systemName: "arrow.up.backward.and.arrow.down.forward")
//                                        .font(.caption.bold())
//                                        .padding(8)
//                                        .background(.thickMaterial)
//                                        .clipShape(Circle())
//                                        .shadow(radius: 2)
//                                }
//                                .padding(8)
//                            }
//
//                            HStack {
//                                Text("Radius:")
//                                    .font(.subheadline)
//                                Spacer()
//                                Text("\(Int(viewModel.searchRadius)) km")
//                                    .font(.headline)
//                                    .foregroundColor(.blue)
//                            }
//                            Slider(value: $viewModel.searchRadius, in: 1...20, step: 1)
//                                .tint(.blue)
//                        }
//                        .padding()
//                        .background(Color(UIColor.secondarySystemBackground))
//                        .cornerRadius(16)
//                        .padding(.horizontal)
//                    }
//
//                    Divider().padding(.vertical, 8)
//
//                    // MARK: Sellers List
//                    VStack(alignment: .leading) {
//                        HStack {
//                            Text("Sellers in Radius")
//                                .font(.title3.bold())
//                            Spacer()
//                            Text("\(viewModel.sellersInRadius.count) Found")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                        }
//                        .padding(.horizontal)
//
//                        if viewModel.isLoadingSellers {
//                            ProgressView()
//                                .frame(maxWidth: .infinity)
//                                .padding(.vertical, 40)
//                        } else if viewModel.sellersInRadius.isEmpty {
//                            VStack(spacing: 8) {
//                                Image(systemName: "tray.fill")
//                                    .font(.largeTitle)
//                                    .foregroundColor(.secondary)
//                                Text("No sellers inside this radius.")
//                                    .font(.subheadline)
//                                    .foregroundColor(.secondary)
//                            }
//                            .padding(.vertical, 40)
//                            .frame(maxWidth: .infinity, alignment: .center)
//                        } else {
//                            LazyVStack(spacing: 16) {
//                                ForEach(viewModel.sellersInRadius) { seller in
//                                    SellerRow(seller: seller)
//                                }
//                            }
//                            .padding(.horizontal)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Marketplace")
//            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Kurunegala, Kaduwela...")
//
//            // MARK: - HIG Compliant Navigation Bar
//            .toolbar {
//                ToolbarItem(placement: .topBarTrailing) {
//                    HStack(spacing: 16) {
//
//                        // 1. Notification Action
//                        Button(action: { viewModel.showNotifications = true }) {
//                            Image(systemName: viewModel.unreadNotificationCount > 0 ? "bell.badge.fill" : "bell.fill")
//                                .font(.title3)
//                                .foregroundColor(.blue)
//                        }
//
//                        // 2. Profile Action (Loads from Xcode Assets)
//                        Button(action: { viewModel.showProfile = true }) {
//                            Image(viewModel.profileImageName)
//                                .resizable()
//                                .scaledToFill()
//                                .frame(width: 32, height: 32)
//                                .clipShape(Circle())
//                        }
//                    }
//                }
//            }
//            // MARK: - Profile / Developer Sheet
//            .sheet(isPresented: $viewModel.showProfile) {
//                NavigationStack {
//                    VStack(spacing: 24) {
//                        Image(systemName: "gearshape.fill")
//                            .font(.system(size: 60))
//                            .foregroundColor(.gray)
//
//                        Text("Developer Options")
//                            .font(.title2.bold())
//
//                        Text("Use these tools during testing to clear your cache and database connections.")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .multilineTextAlignment(.center)
//                            .padding(.horizontal, 32)
//
//                        Button(action: {
//                            AuthManager.shared.signOut()
//                            viewModel.showProfile = false
//                        }) {
//                            Text("Log Out (Clear Session)")
//                                .font(.headline)
//                                .foregroundColor(.white)
//                                .frame(maxWidth: .infinity)
//                                .padding()
//                                .background(Color.red)
//                                .cornerRadius(12)
//                        }
//                        .padding(.horizontal, 24)
//                        .padding(.top, 20)
//
//                        Spacer()
//                    }
//                    .padding(.top, 40)
//                    .navigationTitle("Profile")
//                    .navigationBarTitleDisplayMode(.inline)
//                    .toolbar {
//                        ToolbarItem(placement: .topBarTrailing) {
//                            Button("Done") { viewModel.showProfile = false }
//                        }
//                    }
//                }
//            }
//            .sheet(isPresented: $viewModel.showNotifications) {
//                NavigationStack {
//                    Text("Notifications Placeholder")
//                        .navigationTitle("Notifications")
//                        .navigationBarTitleDisplayMode(.inline)
//                        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { viewModel.showNotifications = false } } }
//                }
//            }
//            .sheet(isPresented: $viewModel.isFullScreenMapPresented) {
//                FullScreenLocationPicker(searchCenter: $viewModel.searchCenter, searchRadius: $viewModel.searchRadius, sellers: viewModel.allSellers)
//            }
//        }
//    }
//}
//
//#Preview {
//    DiscoveryDashboardView()
//}





import SwiftUI
import MapKit

struct DiscoveryDashboardView: View {
    @State private var viewModel = DiscoveryDashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: Contextual Entry to Personal Analytics
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
                                Text("View Performance")
                                    .font(.caption.bold())
                                Image(systemName: "chevron.right")
                                    .font(.caption)
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

                    FilterChipsView(filters: viewModel.filters, selectedFilter: $viewModel.selectedFilter)

                    // MARK: Recommended For You
                    VStack(alignment: .leading) {
                        Text("Recommended For You")
                            .font(.title3.bold())
                            .padding(.horizontal)

                        if viewModel.isLoadingSellers {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        } else if viewModel.recommendedSellers.isEmpty {
                            Text("No sellers available yet.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.recommendedSellers) { seller in
                                        RecommendedSellerCard(seller: seller)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    Divider().padding(.vertical, 8)

                    // MARK: The Inline Preview Map
                    VStack(spacing: 16) {
                        HStack {
                            Text("Find Sellers Near Me")
                                .font(.title3.bold())
                            Spacer()
                        }
                        .padding(.horizontal)

                        VStack(spacing: 12) {
                            Map(position: .constant(.region(MKCoordinateRegion(center: viewModel.searchCenter, latitudinalMeters: viewModel.searchRadius * 2500, longitudinalMeters: viewModel.searchRadius * 2500))), interactionModes: []) {

                                MapCircle(center: viewModel.searchCenter, radius: viewModel.searchRadius * 1000)
                                    .foregroundStyle(.blue.opacity(0.3))

                                Marker("Search Zone", coordinate: viewModel.searchCenter)
                                    .tint(.blue)

                                ForEach(viewModel.sellersInRadius) { seller in
                                    Annotation(seller.sellerName, coordinate: seller.coordinate) {
                                        VStack {
                                            Image(systemName: "leaf.fill")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(Color.green)
                                                .clipShape(Circle())
                                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                        }
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
                                Text("Radius:")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(viewModel.searchRadius)) km")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            Slider(value: $viewModel.searchRadius, in: 1...200, step: 5)
                                .tint(.blue)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

                    Divider().padding(.vertical, 8)

                    // MARK: Sellers List
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Sellers in Radius")
                                .font(.title3.bold())
                            Spacer()
                            Text("\(viewModel.sellersInRadius.count) Found")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        if viewModel.isLoadingSellers {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else if viewModel.sellersInRadius.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "tray.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("No sellers inside this radius.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 40)
                            .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.sellersInRadius) { seller in
                                    SellerRow(seller: seller)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Marketplace")
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search a town e.g. Kurunegala...")
            .overlay(alignment: .top) {
                // Shows while MKLocalSearch is resolving the typed town name
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

            // MARK: - HIG Compliant Navigation Bar
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {

                        // 1. Notification Action
                        Button(action: { viewModel.showNotifications = true }) {
                            Image(systemName: viewModel.unreadNotificationCount > 0 ? "bell.badge.fill" : "bell.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }

                        // 2. Profile Action (Loads from Xcode Assets)
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
            // MARK: - Profile / Developer Sheet
            .sheet(isPresented: $viewModel.showProfile) {
                NavigationStack {
                    VStack(spacing: 24) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("Developer Options")
                            .font(.title2.bold())

                        Text("Use these tools during testing to clear your cache and database connections.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Button(action: {
                            AuthManager.shared.signOut()
                            viewModel.showProfile = false
                        }) {
                            Text("Log Out (Clear Session)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                        Spacer()
                    }
                    .padding(.top, 40)
                    .navigationTitle("Profile")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { viewModel.showProfile = false }
                        }
                    }
                }
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
                FullScreenLocationPicker(searchCenter: $viewModel.searchCenter, searchRadius: $viewModel.searchRadius, sellers: viewModel.allSellers)
            }
        }
    }
}

#Preview {
    DiscoveryDashboardView()
}
