

import SwiftUI

struct BuyerTabView: View {
    @State private var selectedTab = 0

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

            MarketAnalyticsView()
                .tabItem { Label("Analytics", systemImage: selectedTab == 3 ? "chart.xyaxis.line" : "chart.xyaxis.line") }
                .tag(3)
        }
        .tint(.blue)
    }
}

#Preview {
    BuyerTabView()
}
