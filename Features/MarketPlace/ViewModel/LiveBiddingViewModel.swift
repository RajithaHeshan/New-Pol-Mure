import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

@Observable
@MainActor
class LiveBiddingViewModel {

    // MARK: - Lot Data
    let lot: HarvestLot

    // MARK: - Bidding State
    var userBidInput: String = ""
    var currentHighestBid: Double
    var currentHighestBidderID: String = ""
    var isOutbid: Bool = false
    var isPlacingBid: Bool = false

    // MARK: - Current Buyer Identity
    private let currentBuyerID: String
    private let currentBuyerName: String

    // MARK: - Firestore Listener
    private var bidsListener: ListenerRegistration?

    init(lot: HarvestLot) {
        self.lot = lot
        self.currentHighestBid = lot.currentBid
        self.currentBuyerID = Auth.auth().currentUser?.uid ?? ""
        self.currentBuyerName = Auth.auth().currentUser?.displayName ?? "Anonymous"
        attachBidsListener()
    }

    nonisolated func stopListening() {
        Task { @MainActor [weak self] in self?.bidsListener?.remove() }
    }

    deinit {
        stopListening()
    }

    // MARK: - Real-Time Bid Listener
    private func attachBidsListener() {
        bidsListener = Firestore.firestore()
            .collection("bids")
            .whereField("sellerID", isEqualTo: lot.id)
            .order(by: "amount", descending: true)
            .limit(to: 1)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }

                guard let doc = snapshot?.documents.first,
                      let bid = Bid(id: doc.documentID, data: doc.data()) else { return }

                let previousHighest = self.currentHighestBid
                let wasLeading = (self.currentHighestBidderID == self.currentBuyerID)

                self.currentHighestBid = bid.amount
                self.currentHighestBidderID = bid.bidderID

                // Notify buyer only if they were previously leading and someone outbid them
                if wasLeading && bid.bidderID != self.currentBuyerID && bid.amount > previousHighest {
                    self.isOutbid = true
                    self.triggerOutbidNotification(newAmount: bid.amount, bidderName: bid.bidderName)
                }
            }
    }

    // MARK: - Bid Actions
    func incrementBid(by amount: Double) {
        let currentInput = Double(userBidInput) ?? currentHighestBid
        userBidInput = String(format: "%.0f", currentInput + amount)
    }

    func decrementBid() {
        let currentInput = Double(userBidInput) ?? currentHighestBid
        if currentInput > currentHighestBid + 1 {
            userBidInput = String(format: "%.0f", currentInput - 1)
        }
    }

    func placeBid() {
        guard let newBid = Double(userBidInput), newBid > currentHighestBid else { return }
        isPlacingBid = true

        Task {
            do {
                let bidData: [String: Any] = [
                    "sellerID": lot.id,
                    "bidderID": currentBuyerID,
                    "bidderName": currentBuyerName,
                    "amount": newBid,
                    "placedAt": Timestamp()
                ]
                try await Firestore.firestore().collection("bids").addDocument(data: bidData)

                userBidInput = ""
                isOutbid = false
            } catch {
                print("Error placing bid: \(error.localizedDescription)")
            }
            isPlacingBid = false
        }
    }

    // MARK: - Local Push Notification (Outbid Alert)
    private func triggerOutbidNotification(newAmount: Double, bidderName: String) {
        let content = UNMutableNotificationContent()
        content.title = "You've Been Outbid!"
        content.body = "\(bidderName) placed Rs \(String(format: "%.0f", newAmount)) on \(lot.sellerInitial)'s lot. Bid higher to stay in."
        content.sound = .defaultCritical

        let request = UNNotificationRequest(
            identifier: "outbid-\(lot.id)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    // MARK: - Debug / Simulation
    func simulateOutbid() {
        currentHighestBid += 5.0
        isOutbid = true
        triggerOutbidNotification(newAmount: currentHighestBid, bidderName: "Test Buyer")
    }
}
