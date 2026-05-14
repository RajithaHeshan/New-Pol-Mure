import SwiftUI


struct SplashView: View {

    @AppStorage("isLoggedIn")      private var isLoggedIn      = false
    @AppStorage("userRole")        private var userRole        = ""
    @AppStorage("isFaceIDEnabled") private var isFaceIDEnabled = false

   
    @State private var splashDone = false
   
    @State private var destination: Destination = .loading

    enum Destination { case loading, login, faceID, home }

    var body: some View {
        Group {
            switch destination {
            case .loading:
                splashScreen
            case .login:
                LoginView()
            case .faceID:
                FaceIDLockView(
                    onUnlocked: { destination = .home },
                    onPasswordLogin: { destination = .home }
                )
            case .home:
                homeView
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                resolve()
            }
        }
        .onChange(of: isLoggedIn) { _, newValue in
            // Only re-route on logout (newValue == false) or explicit login from non-FaceID screen
            if destination != .faceID {
                resolve()
            }
        }
    }

   
    private func resolve() {
        if !isLoggedIn {
            destination = .login
        } else if isFaceIDEnabled {
            destination = .faceID
        } else {
            destination = .home
        }
    }

   
    private var splashScreen: some View {
        ZStack {
            LinearGradient(
                colors: [Color.polmureEmerald.opacity(0.18), Color(UIColor.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "leaf.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .foregroundColor(.polmureEmerald)

                Text("Polmure")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Coconut Marketplace")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ProgressView()
                    .padding(.top, 24)
                    .tint(.polmureEmerald)
            }
        }
    }

   
    @ViewBuilder
    private var homeView: some View {
        let userID = AuthManager.shared.currentUserID
        if userRole == "BUYER" || userRole == "Buyer" {
            BuyerTabView()
                .id("buyer-\(userID)")
        } else {
            SellerTabView()
                .id("seller-\(userID)")
        }
    }
}
