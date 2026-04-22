import SwiftUI

struct ContentView: View {
   
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("userRole") var userRole: String = ""

    var body: some View {
       
        if isLoggedIn {
            if userRole == "BUYER" || userRole == "Buyer" {
                BuyerTabView()
            } else {
                SellerTabView()
            }
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
}

