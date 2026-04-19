//import SwiftUI
//import MapKit
//
//struct SellerDashboardView: View {
//    @State private var viewModel = SellerDashboardViewModel()
//    
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                VStack(spacing: 20) {
//                    
//                    // MARK: Contextual Entry to Personal Analytics
//                    HStack(spacing: 16) {
//                        NavigationLink(destination: SellerPerformanceView()) {
//                            MetricCard(title: "Escrow Pending", amount: "Rs 145K", icon: "lock.shield.fill", color: .green)
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                        
//                        NavigationLink(destination: SellerPerformanceView()) {
//                            MetricCard(title: "Active Bids", amount: "Rs 185K", icon: "chart.line.uptrend.xyaxis", color: .blue)
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                    }
//                    .padding(.horizontal)
//                    .padding(.top, 10)
//                    
//                    UrgentActionBanner()
//                        .padding(.horizontal)
//                    
//                    Divider().padding(.vertical, 8)
//                    
//                    SellerFilterChipsView(filters: viewModel.filters, selectedFilter: $viewModel.selectedFilter)
//                    
//                    // MARK: Recommended For You
//                    VStack(alignment: .leading, spacing: 12) {
//                        Text("Recommended Buyers")
//                            .font(.title3.bold())
//                            .padding(.horizontal)
//                        
//                        if viewModel.filteredRecommendedBuyers.isEmpty {
//                            Text("No recommendations match this filter.")
//                                .font(.subheadline)
//                                .foregroundColor(.secondary)
//                                .padding(.horizontal)
//                        } else {
//                            ScrollView(.horizontal, showsIndicators: false) {
//                                HStack(spacing: 16) {
//                                    ForEach(viewModel.filteredRecommendedBuyers) { buyer in
//                                        NavigationLink(destination: LiveOfferView(buyer: buyer)) {
//                                            RecommendedBuyerCard(buyer: buyer)
//                                        }
//                                        .buttonStyle(PlainButtonStyle())
//                                    }
//                                }
//                                .padding(.horizontal)
//                            }
//                        }
//                    }
//                    
//                    Divider().padding(.vertical, 8)
//                    
//                    // MARK: Inline Preview Map
//                    VStack(spacing: 16) {
//                        HStack {
//                            Text("Find Buyers Near My Estate")
//                                .font(.title3.bold())
//                            Spacer()
//                        }
//                        .padding(.horizontal)
//                        
//                        VStack(spacing: 12) {
//                            Map(position: .constant(.region(MKCoordinateRegion(center: viewModel.searchCenter, latitudinalMeters: viewModel.searchRadius * 2500, longitudinalMeters: viewModel.searchRadius * 2500))), interactionModes: []) {
//                                
//                                MapCircle(center: viewModel.searchCenter, radius: viewModel.searchRadius * 1000)
//                                    .foregroundStyle(.orange.opacity(0.3))
//                                
//                                Marker("My Estate", coordinate: viewModel.searchCenter)
//                                    .tint(.orange)
//                                
//                                ForEach(viewModel.filteredLocalBuyers) { buyer in
//                                    Annotation(buyer.name, coordinate: buyer.coordinate) {
//                                        VStack {
//                                            Image(systemName: "building.2.fill")
//                                                .font(.headline)
//                                                .foregroundColor(.white)
//                                                .padding(8)
//                                                .background(Color.orange)
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
//                                Text("Delivery Radius:")
//                                    .font(.subheadline)
//                                Spacer()
//                                Text("\(Int(viewModel.searchRadius)) km")
//                                    .font(.headline)
//                                    .foregroundColor(.orange)
//                            }
//                            
//                            Slider(value: $viewModel.searchRadius, in: 1...50, step: 1)
//                                .tint(.orange)
//                        }
//                        .padding()
//                        .background(Color(UIColor.secondarySystemGroupedBackground))
//                        .cornerRadius(16)
//                        .padding(.horizontal)
//                    }
//                    
//                    Divider().padding(.vertical, 8)
//                    
//                    // MARK: Buyers List
//                    VStack(alignment: .leading, spacing: 16) {
//                        HStack {
//                            Text("Buyers in Radius")
//                                .font(.title3.bold())
//                            Spacer()
//                            Text("\(viewModel.filteredLocalBuyers.count) Found")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                        }
//                        .padding(.horizontal)
//                        
//                        if viewModel.filteredLocalBuyers.isEmpty {
//                            VStack(spacing: 8) {
//                                Image(systemName: "tray.fill")
//                                    .font(.largeTitle)
//                                    .foregroundColor(.secondary)
//                                Text("No buyers inside this radius.")
//                                    .font(.subheadline)
//                                    .foregroundColor(.secondary)
//                            }
//                            .padding(.vertical, 40)
//                            .frame(maxWidth: .infinity, alignment: .center)
//                        } else {
//                            LazyVStack(spacing: 16) {
//                                ForEach(viewModel.filteredLocalBuyers) { buyer in
//                                    BuyerRowCard(buyer: buyer)
//                                }
//                            }
//                            .padding(.horizontal)
//                        }
//                    }
//                }
//                .padding(.bottom, 30)
//            }
//            .background(Color(UIColor.systemGroupedBackground))
//            .navigationTitle("Dashboard")
//            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Buyers by name or city...")
//            
//            // MARK: - HIG Compliant Navigation Bar
//            .toolbar {
//                ToolbarItem(placement: .topBarTrailing) {
//                    HStack(spacing: 16) {
//                        // 1. Notification Action
//                        Button(action: { viewModel.showNotifications = true }) {
//                            Image(systemName: viewModel.unreadNotificationCount > 0 ? "bell.badge.fill" : "bell.fill")
//                                .font(.title3)
//                                .foregroundColor(.green)
//                        }
//                        
//                        // 2. Profile Action
//                        Button(action: { viewModel.showProfile = true }) {
//                            Image(systemName: "person.crop.circle.fill")
//                                .font(.title2)
//                                .foregroundColor(.green)
//                        }
//                    }
//                }
//            }
//            // MARK: - Updated Profile / Developer Sheet
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
//                SellerFullScreenLocationPicker(searchCenter: $viewModel.searchCenter, searchRadius: $viewModel.searchRadius, buyers: viewModel.localBuyers)
//            }
//        }
//    }
//}
//
//#Preview {
//    SellerDashboardView()
//}
//
//
//
//
//





// New-Pol-Mure/Features/Marketplace/Views/SellerDashboardView.swift

import SwiftUI
import MapKit

struct SellerDashboardView: View {
    @State private var viewModel = SellerDashboardViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: Metric Cards
                    HStack(spacing: 16) {
                        NavigationLink(destination: SellerPerformanceView()) {
                            MetricCard(title: "Escrow Pending", amount: "Rs 145K", icon: "lock.shield.fill", color: .green)
                        }.buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: SellerPerformanceView()) {
                            MetricCard(title: "Active Bids", amount: "Rs 185K", icon: "chart.line.uptrend.xyaxis", color: .blue)
                        }.buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal).padding(.top, 10)
                    
                    UrgentActionBanner().padding(.horizontal)
                    Divider().padding(.vertical, 8)
                    
                    SellerFilterChipsView(filters: viewModel.filters, selectedFilter: $viewModel.selectedFilter)
                    
                    // MARK: Recommended Buyers
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommended Buyers").font(.title3.bold()).padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.filteredRecommendedBuyers) { buyer in
                                    NavigationLink(destination: LiveOfferView(buyer: buyer)) {
                                        RecommendedBuyerCard(buyer: buyer)
                                    }.buttonStyle(PlainButtonStyle())
                                }
                            }.padding(.horizontal)
                        }
                    }
                    
                    Divider().padding(.vertical, 8)
                    
                    // MARK: Inline Preview Map
                    VStack(spacing: 16) {
                        Text("Find Buyers Near My Estate").font(.title3.bold()).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            Map(position: .constant(.region(MKCoordinateRegion(center: viewModel.searchCenter, latitudinalMeters: viewModel.searchRadius * 2500, longitudinalMeters: viewModel.searchRadius * 2500))), interactionModes: []) {
                                MapCircle(center: viewModel.searchCenter, radius: viewModel.searchRadius * 1000).foregroundStyle(.orange.opacity(0.3))
                                Marker("My Estate", coordinate: viewModel.searchCenter).tint(.orange)
                                ForEach(viewModel.filteredLocalBuyers) { buyer in
                                    Annotation(buyer.name, coordinate: buyer.coordinate) {
                                        Image(systemName: "building.2.fill").font(.headline).foregroundColor(.white).padding(8).background(Color.orange).clipShape(Circle()).shadow(radius: 4)
                                    }
                                }
                            }
                            .frame(height: 140).clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(alignment: .topTrailing) {
                                Button(action: { viewModel.isFullScreenMapPresented = true }) {
                                    Image(systemName: "arrow.up.backward.and.arrow.down.forward").font(.caption.bold()).padding(8).background(.thickMaterial).clipShape(Circle())
                                }.padding(8)
                            }
                            
                            HStack {
                                Text("Delivery Radius:").font(.subheadline)
                                Spacer()
                                Text("\(Int(viewModel.searchRadius)) km").font(.headline).foregroundColor(.orange)
                            }
                            Slider(value: $viewModel.searchRadius, in: 1...50, step: 1).tint(.orange)
                        }
                        .padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).padding(.horizontal)
                    }
                    
                    // MARK: Buyers List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Buyers in Radius").font(.title3.bold()).padding(.horizontal)
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.filteredLocalBuyers) { buyer in
                                BuyerRowCard(buyer: buyer)
                            }
                        }.padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { viewModel.showNotifications = true }) {
                            Image(systemName: viewModel.unreadNotificationCount > 0 ? "bell.badge.fill" : "bell.fill").foregroundColor(.green)
                        }
                        Button(action: { viewModel.showProfile = true }) {
                            // FIXED: Now correctly displays the default avatar asset
                            Image(viewModel.profileImageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.isFullScreenMapPresented) {
                SellerFullScreenLocationPicker(searchCenter: $viewModel.searchCenter, searchRadius: $viewModel.searchRadius, buyers: viewModel.localBuyers)
            }
            .sheet(isPresented: $viewModel.showProfile) {
                // Developer Sheet with Sign Out
                NavigationStack {
                    VStack(spacing: 24) {
                        Button(action: { AuthManager.shared.signOut(); viewModel.showProfile = false }) {
                            Text("Log Out").foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.red).cornerRadius(12)
                        }.padding()
                    }.navigationTitle("Profile")
                }
            }
        }
    }
}


#Preview {
   SellerDashboardView()
}

