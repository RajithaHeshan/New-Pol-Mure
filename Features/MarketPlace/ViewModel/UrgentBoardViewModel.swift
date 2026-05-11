// Location: New-Pol-Mure/Features/MarketPlace/ViewModels/UrgentBoardViewModel.swift

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

    // MARK: - Live Data
    var activeRequests: [UrgentRequest] = []

    // MARK: - Loading & Posting States
    var isLoadingRequests = false
    var isPosting         = false

    // MARK: - Computed: only this buyer's own posts
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

    // MARK: - Fetch Buyer Profile (name + location for new posts)
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

    // MARK: - Live Listener: all urgent requests (sellers can see all; buyer sees filtered via myRequests)
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

    // MARK: - Post New Urgent Request
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
            // Mark this buyer as urgent so sellers see them under "Urgent Need"
            db.collection("users").document(self.currentBuyerID)
                .updateData(["isUrgent": true]) { error in
                    if let error { print("isUrgent update error: \(error.localizedDescription)") }
                }
            self.isPosting = false
            Task { await onSuccess() }
        }
    }

    // MARK: - Delete Urgent Request
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
