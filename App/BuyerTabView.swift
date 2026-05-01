

import SwiftUI

struct BuyerTabView: View {
    @Environment(AppNavigationState.self) private var navState
    @State private var selectedTab = 0
    @State private var analyticsZone: CoconutZone? = nil
    @State private var showPerformance = false
    @State private var showAccount = false

    var body: some View {
        TabView(selection: $selectedTab) {

            DiscoveryDashboardView()
                .tabItem { Label("Market", systemImage: selectedTab == 0 ? "cart.fill" : "cart") }
                .tag(0)

            ActivityDashboardView()
                .tabItem { Label("Activity", systemImage: selectedTab == 1 ? "doc.text.fill" : "doc.text") }
                .badge(2)
                .tag(1)

            UrgentBoardView()
                .tabItem { Label("Urgent", systemImage: selectedTab == 2 ? "flame.fill" : "flame") }
                .tag(2)

            MarketAnalyticsView(preselectedZone: analyticsZone)
                .tabItem { Label("Analytics", systemImage: selectedTab == 3 ? "chart.xyaxis.line" : "chart.xyaxis.line") }
                .tag(3)
        }
        .tint(.blue)
        .sheet(isPresented: $showPerformance) {
            NavigationStack { BuyerPerformanceView() }
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
        .onChange(of: navState.buyerSelectedTab) { _, newTab in
            selectedTab = newTab
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
    BuyerTabView()
}
