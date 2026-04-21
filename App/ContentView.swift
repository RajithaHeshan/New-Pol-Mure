import SwiftUI

struct ContentView: View {
    // Check the Offline Backpack to see if a user is already logged in
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("userRole") var userRole: String = ""

    var body: some View {
        // Route the user based on their saved session
        if isLoggedIn {
            if userRole == "BUYER" || userRole == "Buyer" {
                DiscoveryDashboardView()
            } else {
                SellerDashboardView()
            }
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
}

