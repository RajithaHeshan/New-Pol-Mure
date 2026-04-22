

import SwiftUI

struct SellerTabView: View {
    @State private var selectedTab = 0

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

            MarketAnalyticsView()
                .tabItem { Label("Analytics", systemImage: selectedTab == 3 ? "chart.xyaxis.line" : "chart.xyaxis.line") }
                .tag(3)
        }
        .tint(.green)
    }
}

#Preview {
    SellerTabView()
}
