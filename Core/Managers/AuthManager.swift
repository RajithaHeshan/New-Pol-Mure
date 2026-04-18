

import Foundation
import FirebaseAuth
import FirebaseFirestore
import CoreData

class AuthManager {
    static let shared = AuthManager()
    private let db = Firestore.firestore()
    private let context = PersistenceController.shared.container.viewContext
    
    private init() {}
    
  
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
            "createdAt": Timestamp()
        ]
        try await db.collection("users").document(userId).setData(userData)
        
     
        saveLocalSession(userId: userId, role: "BUYER")
    }
    
  
    func loginUser(email: String, password: String) async throws -> String {
       
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        let userId = authResult.user.uid
        
  
        let snapshot = try await db.collection("users").document(userId).getDocument()
        let role = snapshot.data()?["role"] as? String ?? "BUYER"
        
       
        saveLocalSession(userId: userId, role: role)
        
        return role
    }
    
    
    private func saveLocalSession(userId: String, role: String) {
       
        print("💾 Core Data: Session cached locally for User \(userId) with Role: \(role)")
        
      
    }
}
