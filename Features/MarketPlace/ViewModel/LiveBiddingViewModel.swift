import SwiftUI
import FirebaseFirestore
import UserNotifications

private final class ListenerBox {   
    var listener: ListenerRegistration? //handle realtime data
    init() {}
    deinit { listener?.remove() } // prevent memory leaked
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

    private let currentBuyerID: String
    private var currentBuyerName: String = ""
    private let listenerBox = ListenerBox()
    private var isFirstSnapshot: Bool = true

    init(lot: HarvestLot) {
        self.lot = lot
        self.currentHighestBid = lot.currentBid
        self.currentBuyerID = AuthManager.shared.currentUserID
        fetchBuyerName()
        attachBidsListener()
    }

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


    private func attachBidsListener() {
        listenerBox.listener = Firestore.firestore()
            .collection("bids")
            .whereField("harvestID", isEqualTo: lot.id) // filter only bids only this harvest. all the bid share with other buyres
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Bids listener error: \(error.localizedDescription)")
                    return
                }


                //get all the dids sort in descending order
                let allBids = snapshot?.documents.compactMap {
                    Bid(id: $0.documentID, data: $0.data())
                } ?? []

                //take top one

                guard let topBid = allBids.sorted(by: { $0.amount > $1.amount }).first else {
                    self.isFirstSnapshot = false
                    return
                }



                if self.isFirstSnapshot {  //initial login 
                    self.currentHighestBid = topBid.amount
                    self.currentHighestBidderID = topBid.bidderID
                    self.isFirstSnapshot = false //login initially no outbid notifcation 
                    return
                }

                let previousLeaderID = self.currentHighestBidderID
                self.currentHighestBid = topBid.amount
                self.currentHighestBidderID = topBid.bidderID

                if topBid.bidderID == self.currentBuyerID {
                    self.isOutbid = false
                    return
                }

                let currentBuyerHasBid = allBids.contains { $0.bidderID == self.currentBuyerID } // current buyer inlcude one than bid
                if currentBuyerHasBid && topBid.bidderID != previousLeaderID && !self.isOutbid {
                    self.isOutbid = true
                    self.scheduleOutbidNotification(newAmount: topBid.amount, bidderName: topBid.bidderName) //push notofication 
                }
            }
    }



    func incrementBid(by amount: Double) {
        let currentInput = Double(userBidInput) ?? currentHighestBid  //if textfiedl empty use current higherbid
        userBidInput = String(format: "%.0f", currentInput + amount)
    }

    func decrementBid() {
        let currentInput = Double(userBidInput) ?? currentHighestBid
        if currentInput > currentHighestBid + 1 { // than current higherbid
            userBidInput = String(format: "%.0f", currentInput - 1)
        }
    }

    func placeBid() {
        guard let newBid = Double(userBidInput), newBid > currentHighestBid else { return }
        isPlacingBid = true

        Task {
            do {
                let bidData: [String: Any] = [
                    "harvestID":  lot.id,
                    "sellerID":   lot.sellerID,
                    "sellerName": lot.sellerInitial,
                    "bidderID":   currentBuyerID,
                    "bidderName": currentBuyerName,
                    "amount":     newBid,
                    "status":     "pending",
                    "placedAt":   Timestamp()
                ]
                try await Firestore.firestore().collection("bids").addDocument(data: bidData)
                userBidInput = ""
                scheduleNewBidNotification(amount: newBid)
            } catch {
                print("Error placing bid: \(error.localizedDescription)")
            }
            isPlacingBid = false
        }
    }

    func simulateOutbid() {
        let simulatedAmount = currentHighestBid + 5.0
        currentHighestBid = simulatedAmount
        currentHighestBidderID = "simulated-other-buyer"
        isOutbid = true
        scheduleOutbidNotification(newAmount: simulatedAmount, bidderName: "Test Buyer")
    }

    private func scheduleNewBidNotification(amount: Double) {
        let lotID = lot.id
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = "New Bid Received!"
            content.body  = "\(self.currentBuyerName) placed Rs \(String(format: "%.0f", amount)) on your lot. Review it in Activity → Direct Bids."
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: "newbid-\(lotID)-\(Date().timeIntervalSince1970)",
                content: content, trigger: nil
            )
            UNUserNotificationCenter.current().add(request) { error in
                if let error { print("New bid notification error: \(error.localizedDescription)") }
            }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func scheduleOutbidNotification(newAmount: Double, bidderName: String) {  //exceed bid 
        let sellerName = lot.sellerInitial
        let lotID = lot.id
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = "You've Been Outbid!"
            content.body  = "\(bidderName) placed Rs \(String(format: "%.0f", newAmount)) on \(sellerName)'s lot. Bid higher to stay in."
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: "outbid-\(lotID)-\(Date().timeIntervalSince1970)",
                content: content, trigger: nil
            )
            UNUserNotificationCenter.current().add(request) { error in
                if let error { print("Notification error: \(error.localizedDescription)") }
            }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
