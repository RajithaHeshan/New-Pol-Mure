
import SwiftUI
import FirebaseFirestore

private final class UrgentBoardListenerBox {
    var listener: ListenerRegistration?
    init() {}
    deinit { listener?.remove() }
}

@Observable
@MainActor
class UrgentBoardViewModel {

   
    var activeRequests: [UrgentRequest] = []

  
    var isLoadingRequests = false
    var isPosting         = false

    
    var myRequests: [UrgentRequest] {
        activeRequests.filter { $0.buyerID == currentBuyerID }
    }

    private let currentBuyerID: String
    private var currentBuyerName: String     = ""
    private var currentBuyerLocation: String = ""

    private let requestsListenerBox = UrgentBoardListenerBox()

    init() {
        self.currentBuyerID = AuthManager.shared.currentUserID
        fetchBuyerProfile()
        attachRequestsListener()
    }

  
    private func fetchBuyerProfile() {
        guard !currentBuyerID.isEmpty else { return }

        Firestore.firestore()
            .collection("users")
            .document(currentBuyerID)
            .getDocument { [weak self] snapshot, error in
                guard let self, let data = snapshot?.data() else { return }
                self.currentBuyerName     = data["fullName"]     as? String ?? ""
                self.currentBuyerLocation = data["locationName"] as? String ?? ""
            }
    }


   
    private func attachRequestsListener() {
        guard !currentBuyerID.isEmpty else { return }
        isLoadingRequests = true

        requestsListenerBox.listener = Firestore.firestore()
            .collection("urgentRequests")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("UrgentRequests listener error: \(error.localizedDescription)")
                    self.isLoadingRequests = false
                    return
                }

                self.activeRequests = snapshot?.documents.compactMap {
                    UrgentRequest(id: $0.documentID, data: $0.data())
                }.sorted { $0.deadline < $1.deadline } ?? []

                self.isLoadingRequests = false
            }
    }


//sellers can view in Urgent need section 
  
    func postUrgentRequest(quantity: Int, grade: String, deadline: Date, onSuccess: @escaping @MainActor () -> Void = {}) {
        guard !currentBuyerID.isEmpty else { return }
        isPosting = true

        let data: [String: Any] = [
            "buyerID":   currentBuyerID,
            "buyerName": currentBuyerName,
            "quantity":  quantity,
            "grade":     grade,
            "location":  currentBuyerLocation,
            "deadline":  Timestamp(date: deadline)
        ]

        let db = Firestore.firestore()
        db.collection("urgentRequests").addDocument(data: data) { [weak self] error in
            guard let self else { return }
            if let error {
                print("Post urgent request error: \(error.localizedDescription)")
                self.isPosting = false
                return
            }
           
            db.collection("users").document(self.currentBuyerID)
                .updateData(["isUrgent": true]) { error in
                    if let error { print("isUrgent update error: \(error.localizedDescription)") }
                }
            self.isPosting = false
            Task { await onSuccess() }
        }
    }

 
    func deleteRequest(_ request: UrgentRequest) {
        let db = Firestore.firestore()
        db.collection("urgentRequests").document(request.id).delete { [weak self] error in
            guard let self else { return }
            if let error { print("Delete urgent request error: \(error.localizedDescription)"); return }

            // If the buyer has no more active requests, clear the urgent flag
            let remaining = self.myRequests.filter { $0.id != request.id }
            if remaining.isEmpty {
                db.collection("users").document(self.currentBuyerID)
                    .updateData(["isUrgent": false]) { error in
                        if let error { print("isUrgent clear error: \(error.localizedDescription)") }
                    }
            }
        }
    }
}
