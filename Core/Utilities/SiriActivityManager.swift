import Foundation
import Intents
import UIKit

enum SiriActivityType: String, CaseIterable {
    case checkPrice      = "com.newpolmure.checkprice"
    case openActivity    = "com.newpolmure.openactivity"
    case openUrgent      = "com.newpolmure.openurgent"
    case openNewHarvest  = "com.newpolmure.opennewharvest"
    case openAccount     = "com.newpolmure.openaccount"
    case openPerformance = "com.newpolmure.openperformance"

    var title: String {
        switch self {
        case .checkPrice:      return "Check coconut price in Kandy"
        case .openActivity:    return "Open Activity tab"
        case .openUrgent:      return "Open Urgent tab"
        case .openNewHarvest:  return "Open New Harvest tab"
        case .openAccount:     return "Open Account"
        case .openPerformance: return "Open View Performance"
        }
    }
}

final class SiriActivityManager {

    static let shared = SiriActivityManager()
    private var activities: [String: NSUserActivity] = [:]

    private init() {}

    func donateAll() {
        for type in SiriActivityType.allCases {
            donateActivity(type)
        }
    }

    private func donateActivity(_ type: SiriActivityType) {
        let activity = NSUserActivity(activityType: type.rawValue)
        activity.title = type.title
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.isEligibleForHandoff = false
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(type.rawValue)

        if type == .checkPrice {
            activity.userInfo = ["zone": "kandy"]
        }

        // Store strong reference
        activities[type.rawValue] = activity

        // Must call becomeCurrent on main thread
        DispatchQueue.main.async {
            activity.becomeCurrent()
        }
    }

    func donate(_ type: SiriActivityType, zone: String? = nil) {
        donateActivity(type)
    }
}
