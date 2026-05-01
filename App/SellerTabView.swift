

import SwiftUI

struct SellerTabView: View {
    @Environment(AppNavigationState.self) private var navState
    @State private var selectedTab = 0
    @State private var analyticsZone: CoconutZone? = nil
    @State private var showPerformance = false
    @State private var showAccount = false

    var body: some View {
        TabView(selection: $selectedTab) {

            SellerDashboardView()
                .tabItem { Label("Dashboard", systemImage: selectedTab == 0 ? "square.grid.2x2.fill" : "square.grid.2x2") }
                .tag(0)

            SellerActivityDashboardView()
                .tabItem { Label("Activity", systemImage: selectedTab == 1 ? "doc.text.fill" : "doc.text") }
                .badge(1)
                .tag(1)

            HarvestCreatorView()
                .tabItem { Label("New Harvest", systemImage: selectedTab == 2 ? "plus.app.fill" : "plus.app") }
                .tag(2)

            MarketAnalyticsView(preselectedZone: analyticsZone)
                .tabItem { Label("Analytics", systemImage: selectedTab == 3 ? "chart.xyaxis.line" : "chart.xyaxis.line") }
                .tag(3)
        }
        .tint(.green)
        .sheet(isPresented: $showPerformance) {
            NavigationStack { SellerPerformanceView() }
        }
        .sheet(isPresented: $showAccount) {
            NavigationStack { ProfileView() }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                SiriActivityManager.shared.donateAll()
            }
        }
        // React when Siri fires a navigation command
        .onChange(of: navState.sellerSelectedTab) { _, newTab in
            guard newTab >= 0 else { return }
            selectedTab = newTab
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navState.sellerSelectedTab = -1
            }
        }
        .onChange(of: navState.requestedZone) { _, zoneID in
            guard let zoneID else { return }
            analyticsZone = CoconutZone.allZones.first { $0.id == zoneID }
            selectedTab = 3
            navState.requestedZone = nil
        }
        .onChange(of: navState.showPerformance) { _, show in
            guard show else { return }
            showPerformance = true
            navState.showPerformance = false
        }
        .onChange(of: navState.showAccount) { _, show in
            guard show else { return }
            showAccount = true
            navState.showAccount = false
        }
    }
}

#Preview {
    SellerTabView()
}
