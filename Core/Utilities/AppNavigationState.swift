import SwiftUI

@Observable
final class AppNavigationState {
    static let shared = AppNavigationState()

    var buyerSelectedTab: Int = 0
    var sellerSelectedTab: Int = 0
    var requestedZone: String? = nil      // set when Siri triggers checkPrice
    var showPerformance: Bool = false
    var showAccount: Bool = false

    private init() {}

    // Called from App when a Siri shortcut fires
    func handle(activityType: String, userInfo: [AnyHashable: Any]?) {
        guard let type = SiriActivityType(rawValue: activityType) else { return }

        switch type {
        case .checkPrice:
            requestedZone = userInfo?["zone"] as? String
            buyerSelectedTab  = 3   // Analytics tab (buyer)
            sellerSelectedTab = 3   // Analytics tab (seller)

        case .openActivity:
            buyerSelectedTab  = 1
            sellerSelectedTab = 1

        case .openUrgent:
            buyerSelectedTab = 2    // Buyer only

        case .openNewHarvest:
            sellerSelectedTab = 2   // Seller only

        case .openAccount:
            showAccount = true

        case .openPerformance:
            showPerformance = true
        }
    }
}
