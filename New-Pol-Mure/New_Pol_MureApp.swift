//
//  New_Pol_MureApp.swift
//  New-Pol-Mure
//
//  Created by Heshan Dunumala on 2026-04-09.
//

import SwiftUI
import CoreData

@main
struct New_Pol_MureApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
