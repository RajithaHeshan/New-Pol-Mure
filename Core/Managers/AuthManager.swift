//
//
//import Foundation
//import FirebaseAuth
//import FirebaseFirestore
//import CoreData
//
//class AuthManager {
//    static let shared = AuthManager()
//    private let db = Firestore.firestore()
//    private let context = PersistenceController.shared.container.viewContext
//    
//    private init() {}
//    
//  
//    func registerBuyer(email: String, password: String, fullName: String, volume: String, locationName: String) async throws {
//       
//        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
//        let userId = authResult.user.uid
//        
//      
//        let userData: [String: Any] = [
//            "id": userId,
//            "role": "BUYER",
//            "email": email,
//            "fullName": fullName,
//            "typicalVolume": volume,
//            "locationName": locationName,
//            "createdAt": Timestamp()
//        ]
//        try await db.collection("users").document(userId).setData(userData)
//        
//     
//        saveLocalSession(userId: userId, role: "BUYER")
//    }
//    
//  
//    func loginUser(email: String, password: String) async throws -> String {
//       
//        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
//        let userId = authResult.user.uid
//        
//  
//        let snapshot = try await db.collection("users").document(userId).getDocument()
//        let role = snapshot.data()?["role"] as? String ?? "BUYER"
//        
//       
//        saveLocalSession(userId: userId, role: role)
//        
//        return role
//    }
//    
//    
//    private func saveLocalSession(userId: String, role: String) {
//       
//        print("💾 Core Data: Session cached locally for User \(userId) with Role: \(role)")
//        
//      
//    }
//}







// Location: New-Pol-Mure/Core/Managers/AuthManager.swift

import Foundation
import FirebaseAuth
import FirebaseFirestore
import CoreData
import SwiftUI

class AuthManager {
    // Singleton Instance
    static let shared = AuthManager()
    
    // Database References
    private let db = Firestore.firestore()
    private let context = PersistenceController.shared.container.viewContext
    
    private init() {}
    
    // MARK: - Registration Backend (Buyer)
    func registerBuyer(email: String, password: String, fullName: String, volume: String, locationName: String) async throws {
        
        // 1. Create Secure Credentials in Firebase Auth
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let userId = authResult.user.uid
        
        // 2. Save Extended Profile to Firestore
        let userData: [String: Any] = [
            "id": userId,
            "role": "BUYER",
            "email": email,
            "fullName": fullName,
            "typicalVolume": volume,
            "locationName": locationName,
            "profileImageName": "Gemini_Generated_Image_l5uvm3l5uvm3l5uv",
            "createdAt": Timestamp()
        ]
        try await db.collection("users").document(userId).setData(userData)
        
        // 3. Cache Session in Core Data AND trigger UI Navigation
        saveLocalSession(userId: userId, role: "BUYER")
    }
    
    // MARK: - Login Backend
    func loginUser(email: String, password: String) async throws -> String {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        let userId = authResult.user.uid
        
        let snapshot = try await db.collection("users").document(userId).getDocument()
        let role = snapshot.data()?["role"] as? String ?? "BUYER"
        
        saveLocalSession(userId: userId, role: role)
        return role
    }
    
    // MARK: - Logout Backend
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out of Firebase: \(error.localizedDescription)")
        }
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "LocalSession")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try? context.execute(deleteRequest)
        
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.set("", forKey: "userRole")
        
        print("🚪 User securely signed out. All local data cleared.")
    }
    
    // MARK: - Core Data Helper
    private func saveLocalSession(userId: String, role: String) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "LocalSession")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try? context.execute(deleteRequest)
        
        let newSession = LocalSession(context: context)
        newSession.userId = userId
        newSession.role = role
        
        do {
            try context.save()
            
            // THE FIX: Tell ContentView's @AppStorage to flip the screen automatically!
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            UserDefaults.standard.set(role, forKey: "userRole")
            
            print("💾 Core Data: Session cached locally for User \(userId) with Role: \(role)")
        } catch {
            print("💾 Core Data Error: Failed to cache session - \(error.localizedDescription)")
        }
    }
}
