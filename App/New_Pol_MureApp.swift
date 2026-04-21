//import SwiftUI
//import CoreData
//// 1. Import FirebaseCore to access the initialization methods
//import FirebaseCore
//
//// 2. Create the AppDelegate to configure Firebase as soon as the app launches
//class AppDelegate: NSObject, UIApplicationDelegate {
//    func application(_ application: UIApplication,
//                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        
//        // Wakes up Firebase using your GoogleService-Info.plist file
//        FirebaseApp.configure()
//        
//        return true
//    }
//}
//
//@main
//struct New_Pol_MureApp: App {
//    // 3. Connect the AppDelegate to your SwiftUI lifecycle
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//    
//    // Core Data Persistence
//    let persistenceController = PersistenceController.shared
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
//        }
//    }
//}




import SwiftUI
import CoreData
import FirebaseCore
import UserNotifications  // ← NEW

// AppDelegate configures Firebase and handles notification permission at launch
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {  // ← NEW: added UNUserNotificationCenterDelegate

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Wakes up Firebase using your GoogleService-Info.plist file
        FirebaseApp.configure()

        // ← NEW: Set delegate and request permission once at launch so notifications
        //        always show — even when the app is in the foreground
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error { print("Notification permission error: \(error.localizedDescription)") }
            print("Notification permission granted: \(granted)")
        }

        return true
    }

    // ← NEW: Show banner + sound even when app is open (foreground notifications)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct New_Pol_MureApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
