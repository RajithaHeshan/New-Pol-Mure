import Foundation
import FirebaseAuth
import FirebaseFirestore
import CoreData
import SwiftUI

class AuthManager {
    static let shared = AuthManager()
    private let db = Firestore.firestore()
    private let context = PersistenceController.shared.container.viewContext
    
    private init() {}
    
    // MARK: - Registration Backend (Buyer)
    func registerBuyer(email: String, password: String, fullName: String, volume: String, locationName: String) async throws {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let userId = authResult.user.uid
        
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
        saveLocalSession(userId: userId, role: "BUYER")
    }
    
    // MARK: - Registration Backend (Seller)
    func registerSeller(email: String, password: String, fullName: String, phone: String, yield: String, cycle: String, nextHarvestDate: Date, certification: String, locationName: String, latitude: Double, longitude: Double) async throws {

        // 1. Create Secure Credentials
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let userId = authResult.user.uid

        // 2. Save Seller Profile to Firestore (latitude/longitude enable Buyer map discovery)
        let userData: [String: Any] = [
            "id": userId,
            "role": "SELLER", // Triggers routing to SellerDashboardView
            "email": email,
            "fullName": fullName,
            "phone": phone,
            "typicalYield": yield,
            "harvestCycle": cycle,
            "nextHarvestDate": Timestamp(date: nextHarvestDate),
            "certificationLevel": certification,
            "locationName": locationName,
            "latitude": latitude,
            "longitude": longitude,
            "profileImageName": "Gemini_Generated_Image_bvc5lzbvc5lzbvc5", // Your specific seller asset
            "createdAt": Timestamp()
        ]
        try await db.collection("users").document(userId).setData(userData)
        
        // 3. Cache Session & Route
        saveLocalSession(userId: userId, role: "SELLER")
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
        do { try Auth.auth().signOut() } catch { print("Error signing out: \(error.localizedDescription)") }
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "LocalSession")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try? context.execute(deleteRequest)
        
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.set("", forKey: "userRole")
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
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            UserDefaults.standard.set(role, forKey: "userRole")
        } catch {
            print("Core Data Error: \(error.localizedDescription)")
        }
    }
}

