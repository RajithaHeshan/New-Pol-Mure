import SwiftUI
import CoreData
import FirebaseCore
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error { print("Notification permission error: \(error.localizedDescription)") }
            print("Notification permission granted: \(granted)")
        }

        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // Handle Siri shortcut when app is launched from background
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        let type = userActivity.activityType
        let info = userActivity.userInfo

        // Direct activity type match (NSUserActivity based)
        if type.contains("newpolmure") {
            AppNavigationState.shared.handle(activityType: type, userInfo: info)
            return true
        }

        // continueInApp from intent handler — read action from userInfo
        if let action = info?["action"] as? String {
            AppNavigationState.shared.handle(
                activityType: "com.newpolmure.\(action)",
                userInfo: info
            )
            return true
        }

        // Intent class name fallback — iOS sometimes passes the intent class name as activityType
        switch type {
        case "OpenActivityIntentIntent":
            AppNavigationState.shared.handle(activityType: "com.newpolmure.openactivity", userInfo: nil)
        case "OpenUrgentIntentIntent":
            AppNavigationState.shared.handle(activityType: "com.newpolmure.openurgent", userInfo: nil)
        case "OpenNewHarvestIntentIntent":
            AppNavigationState.shared.handle(activityType: "com.newpolmure.opennewharvest", userInfo: nil)
        case "OpenPerformanceIntentIntent":
            AppNavigationState.shared.handle(activityType: "com.newpolmure.openperformance", userInfo: nil)
        default: break
        }
        return true
    }

    // Handle deep link URLs — used by Shortcuts app on simulator
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard url.scheme == "newpolmure" else { return false }
        let action = url.host ?? ""
        switch action {
        case "activity":    AppNavigationState.shared.handle(activityType: SiriActivityType.openActivity.rawValue,    userInfo: nil)
        case "urgent":      AppNavigationState.shared.handle(activityType: SiriActivityType.openUrgent.rawValue,      userInfo: nil)
        case "newharvest":  AppNavigationState.shared.handle(activityType: SiriActivityType.openNewHarvest.rawValue,  userInfo: nil)
        case "account":     AppNavigationState.shared.handle(activityType: SiriActivityType.openAccount.rawValue,     userInfo: nil)
        case "performance": AppNavigationState.shared.handle(activityType: SiriActivityType.openPerformance.rawValue, userInfo: nil)
        case "checkprice":
            let zone = url.pathComponents.dropFirst().first ?? "kandy"
            AppNavigationState.shared.handle(activityType: SiriActivityType.checkPrice.rawValue, userInfo: ["zone": zone])
        default: return false
        }
        return true
    }
}

@main
struct New_Pol_MureApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    let persistenceController = PersistenceController.shared
    private let navState = AppNavigationState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(navState)
                // Handle via NSUserActivity activity types
                .onContinueUserActivity(SiriActivityType.checkPrice.rawValue)     { navState.handle(activityType: $0.activityType, userInfo: $0.userInfo) }
                .onContinueUserActivity(SiriActivityType.openActivity.rawValue)   { navState.handle(activityType: $0.activityType, userInfo: $0.userInfo) }
                .onContinueUserActivity(SiriActivityType.openUrgent.rawValue)     { navState.handle(activityType: $0.activityType, userInfo: $0.userInfo) }
                .onContinueUserActivity(SiriActivityType.openNewHarvest.rawValue) { navState.handle(activityType: $0.activityType, userInfo: $0.userInfo) }
                .onContinueUserActivity(SiriActivityType.openAccount.rawValue)    { navState.handle(activityType: $0.activityType, userInfo: $0.userInfo) }
                .onContinueUserActivity(SiriActivityType.openPerformance.rawValue){ navState.handle(activityType: $0.activityType, userInfo: $0.userInfo) }
                // Handle via intent class names (continueInApp path)
                .onContinueUserActivity("OpenActivityIntentIntent")    { _ in navState.handle(activityType: "com.newpolmure.openactivity",    userInfo: nil) }
                .onContinueUserActivity("OpenUrgentIntentIntent")      { _ in navState.handle(activityType: "com.newpolmure.openurgent",      userInfo: nil) }
                .onContinueUserActivity("OpenNewHarvestIntentIntent")  { _ in navState.handle(activityType: "com.newpolmure.opennewharvest",  userInfo: nil) }
                .onContinueUserActivity("OpenPerformanceIntentIntent") { _ in navState.handle(activityType: "com.newpolmure.openperformance", userInfo: nil) }
        }
    }
}
