import Intents
import UIKit

// Handles all 4 custom intents defined in NewPolMureIntents.intentdefinition
// Xcode auto-generates doubled class names e.g. OpenActivityIntentIntent

@objc(IntentHandler)
class IntentHandler: INExtension,
    OpenActivityIntentIntentHandling,
    OpenUrgentIntentIntentHandling,
    OpenNewHarvestIntentIntentHandling,
    OpenPerformanceIntentIntentHandling {

    // MARK: - Open Activity Tab
    func handle(intent: OpenActivityIntentIntent) async -> OpenActivityIntentIntentResponse {
        let activity = NSUserActivity(activityType: "com.newpolmure.openactivity")
        activity.title = "Open Activity Tab"
        return OpenActivityIntentIntentResponse(code: .continueInApp, userActivity: activity)
    }

    // MARK: - Open Urgent Tab
    func handle(intent: OpenUrgentIntentIntent) async -> OpenUrgentIntentIntentResponse {
        let activity = NSUserActivity(activityType: "com.newpolmure.openurgent")
        activity.title = "Open Urgent Tab"
        return OpenUrgentIntentIntentResponse(code: .continueInApp, userActivity: activity)
    }

    // MARK: - Open New Harvest Tab
    func handle(intent: OpenNewHarvestIntentIntent) async -> OpenNewHarvestIntentIntentResponse {
        let activity = NSUserActivity(activityType: "com.newpolmure.opennewharvest")
        activity.title = "Open New Harvest Tab"
        return OpenNewHarvestIntentIntentResponse(code: .continueInApp, userActivity: activity)
    }

    // MARK: - Open Performance
    func handle(intent: OpenPerformanceIntentIntent) async -> OpenPerformanceIntentIntentResponse {
        let activity = NSUserActivity(activityType: "com.newpolmure.openperformance")
        activity.title = "Open View Performance"
        return OpenPerformanceIntentIntentResponse(code: .continueInApp, userActivity: activity)
    }
}
