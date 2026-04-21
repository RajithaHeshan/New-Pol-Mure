// Location: New-Pol-Mure/Features/MarketPlace/ViewModels/UrgentBoardViewModel.swift

import SwiftUI
import FirebaseAuth
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
        self.currentBuyerID = Auth.auth().currentUser?.uid ?? ""
        fetchBuyerProfile()
        attachRequestsListener()
    }

    // MARK: - Fetch Buyer Profile (name + location for new posts)
    private func fetchBuyerProfile() {
        guard !currentBuyerID.isEmpty else { return }

        Firestore.firestore()
            .collection("buyers")
            .document(currentBuyerID)
            .getDocument { [weak self] snapshot, error in
                guard let self, let data = snapshot?.data() else { return }
                self.currentBuyerName     = data["name"]     as? String ?? ""
                self.currentBuyerLocation = data["location"] as? String ?? ""
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
    func postUrgentRequest(quantity: Int, grade: String, deadline: Date) {
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

        Firestore.firestore()
            .collection("urgentRequests")
            .addDocument(data: data) { [weak self] error in
                guard let self else { return }
                if let error {
                    print("Post urgent request error: \(error.localizedDescription)")
                }
                self.isPosting = false
            }
    }
}
