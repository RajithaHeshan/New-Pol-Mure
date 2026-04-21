
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications


private final class ListenerBox {
    var listener: ListenerRegistration?
    init() {}
    deinit { listener?.remove() }
}

@Observable
@MainActor
class LiveBiddingViewModel {

    let lot: HarvestLot

   
    var userBidInput: String = ""
    var currentHighestBid: Double
    var currentHighestBidderID: String = ""
    var isOutbid: Bool = false
    var isPlacingBid: Bool = false

    // MARK: - Current Buyer Identity
    private let currentBuyerID: String
    private var currentBuyerName: String = ""

    // MARK: - Firestore Listener (held in nonisolated box — safe to release from deinit)
    private let listenerBox = ListenerBox()

    // First snapshot only syncs current state — never triggers an outbid alert
    private var isFirstSnapshot: Bool = true

    init(lot: HarvestLot) {
        self.lot = lot
        self.currentHighestBid = lot.currentBid
        self.currentBuyerID = Auth.auth().currentUser?.uid ?? ""
        fetchBuyerName()
        attachBidsListener()
    }

    // MARK: - Fetch Buyer Name from Firestore (fullName saved during registration)
    private func fetchBuyerName() {
        guard !currentBuyerID.isEmpty else { return }
        Task {
            let doc = try? await Firestore.firestore()
                .collection("users")
                .document(currentBuyerID)
                .getDocument()
            if let name = doc?.data()?["fullName"] as? String {
                currentBuyerName = name
            }
        }
    }

    // MARK: - Real-Time Bid Listener
    // No .order(by:) — avoids Firestore composite index requirement.
    // Sorting is done in Swift after receiving all bids for this seller.
    private func attachBidsListener() {
        listenerBox.listener = Firestore.firestore()
            .collection("bids")
            .whereField("sellerID", isEqualTo: lot.id)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Bids listener error: \(error.localizedDescription)")
                    return
                }

                let allBids = snapshot?.documents.compactMap {
                    Bid(id: $0.documentID, data: $0.data())
                } ?? []

                guard let topBid = allBids.sorted(by: { $0.amount > $1.amount }).first else {
                    self.isFirstSnapshot = false
                    return
                }

                // First fire — just sync state, never alert
                if self.isFirstSnapshot {
                    self.currentHighestBid = topBid.amount
                    self.currentHighestBidderID = topBid.bidderID
                    self.isFirstSnapshot = false
                    return
                }

                let previousLeaderID = self.currentHighestBidderID
                self.currentHighestBid = topBid.amount
                self.currentHighestBidderID = topBid.bidderID

                // Outbid: someone else is now leading AND current buyer was leading before
                if topBid.bidderID != self.currentBuyerID && previousLeaderID == self.currentBuyerID {
                    self.isOutbid = true
                    self.scheduleOutbidNotification(newAmount: topBid.amount, bidderName: topBid.bidderName)
                }

                // Current buyer re-took the lead — clear outbid state
                if topBid.bidderID == self.currentBuyerID {
                    self.isOutbid = false
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
            } catch {
                print("Error placing bid: \(error.localizedDescription)")
            }
            isPlacingBid = false
        }
    }

    // MARK: - Local Push Notification (Outbid Alert)
    private func scheduleOutbidNotification(newAmount: Double, bidderName: String) {
        let sellerName = lot.sellerInitial
        let lotID = lot.id

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("Notifications not authorized — status: \(settings.authorizationStatus.rawValue)")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "You've Been Outbid!"
            content.body = "\(bidderName) placed Rs \(String(format: "%.0f", newAmount)) on \(sellerName)'s lot. Bid higher to stay in."
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "outbid-\(lotID)-\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("Notification error: \(error.localizedDescription)")
                } else {
                    print("Outbid notification scheduled successfully for \(bidderName)")
                }
            }
        }

        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    // MARK: - Debug / Simulation
    func simulateOutbid() {
        let simulatedAmount = currentHighestBid + 5.0
        currentHighestBid = simulatedAmount
        currentHighestBidderID = "simulated-other-buyer"
        isOutbid = true
        scheduleOutbidNotification(newAmount: simulatedAmount, bidderName: "Test Buyer")
    }
}
