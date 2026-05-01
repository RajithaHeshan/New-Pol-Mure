import SwiftUI

@Observable
final class AppNavigationState {
    static let shared = AppNavigationState()

    var buyerSelectedTab: Int = -1
    var sellerSelectedTab: Int = -1
    var requestedZone: String? = nil      // set when Siri triggers checkPrice
    var showPerformance: Bool = false
    var showAccount: Bool = false

    private init() {}

   
    func handle(activityType: String, userInfo: [AnyHashable: Any]?) {
        guard let type = SiriActivityType(rawValue: activityType) else { return }

        // Reset sheet states so previous runs don't interfere
        showPerformance = false
        showAccount = false

        switch type {
        case .checkPrice:
            requestedZone = userInfo?["zone"] as? String
            buyerSelectedTab  = 3
            sellerSelectedTab = 3

        case .openActivity:
            buyerSelectedTab  = 1
            sellerSelectedTab = 1

        case .openUrgent:
            buyerSelectedTab = 2

        case .openNewHarvest:
            sellerSelectedTab = 2

        case .openAccount:
            showAccount = true

        case .openPerformance:
            showPerformance = true
        }
    }
}
