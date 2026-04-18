//
//  New_Pol_MureApp.swift
//  New-Pol-Mure
//
//  Created by Heshan Dunumala on 2026-04-09.
//

//import SwiftUI
//import CoreData
//
//@main
//struct New_Pol_MureApp: App {
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
// 1. Import FirebaseCore to access the initialization methods
import FirebaseCore

// 2. Create the AppDelegate to configure Firebase as soon as the app launches
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Wakes up Firebase using your GoogleService-Info.plist file
        FirebaseApp.configure()
        
        return true
    }
}

@main
struct New_Pol_MureApp: App {
    // 3. Connect the AppDelegate to your SwiftUI lifecycle
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Core Data Persistence
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
