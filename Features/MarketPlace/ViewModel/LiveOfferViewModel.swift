import SwiftUI
import MapKit
import FirebaseFirestore
import UserNotifications

private final class OfferListenerBox {
    var listener: ListenerRegistration?
    init() {}
    deinit { listener?.remove() }
}

@Observable
@MainActor
class LiveOfferViewModel {
    let buyer: RegisteredBuyer

    var userOfferInput: String = ""
    var currentHighestOffer: Double
    var currentHighestSellerID: String = ""
    var isOutpitched: Bool = false
    var isPlacingOffer: Bool = false
    var isUrgentPitch: Bool = false

    private let currentSellerID: String
    private var currentSellerName: String = ""
    private let listenerBox = OfferListenerBox()
    private var hasLoadedOnce: Bool = false

    init(buyer: RegisteredBuyer, currentMarketPrice: Double = 120.0, isUrgentPitch: Bool = false) {
        self.buyer = buyer
        self.currentHighestOffer = currentMarketPrice
        self.currentSellerID = AuthManager.shared.currentUserID
        self.isUrgentPitch = isUrgentPitch
        fetchSellerName()
        attachOffersListener()
    }

    private func fetchSellerName() {
        guard !currentSellerID.isEmpty else { return }
        Task {
            let doc = try? await Firestore.firestore()
                .collection("users")
                .document(currentSellerID)
                .getDocument()
            if let name = doc?.data()?["fullName"] as? String {
                currentSellerName = name
            }
        }
    }

    private func attachOffersListener() {
        listenerBox.listener = Firestore.firestore()
            .collection("offers")
            .whereField("buyerID", isEqualTo: buyer.id)
            .whereField("isUrgentPitch", isEqualTo: isUrgentPitch)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Offers listener error: \(error.localizedDescription)")
                    return
                }

                let allOffers = snapshot?.documents.compactMap {
                    Offer(id: $0.documentID, data: $0.data())
                } ?? []

                guard let highestOffer = allOffers.sorted(by: { $0.amount > $1.amount }).first else {
                    return
                }

                let previousLeaderID = self.currentHighestSellerID
                self.currentHighestOffer = highestOffer.amount
                self.currentHighestSellerID = highestOffer.sellerID

                if highestOffer.sellerID == self.currentSellerID {
                    self.isOutpitched = false
                    self.hasLoadedOnce = true
                    return
                }

                let thisSellerHasOffer = allOffers.contains { $0.sellerID == self.currentSellerID }
                // Only fire notification for genuine NEW outpitched events — not on first load
                if self.hasLoadedOnce && thisSellerHasOffer && highestOffer.sellerID != previousLeaderID && !self.isOutpitched {
                    self.isOutpitched = true
                    self.scheduleOutpitchedNotification(
                        newAmount: highestOffer.amount,
                        sellerName: highestOffer.sellerName
                    )
                }
                self.hasLoadedOnce = true
            }
    }

    func incrementOffer(by amount: Double) {
        let currentInput = Double(userOfferInput) ?? currentHighestOffer
        userOfferInput = String(format: "%.0f", currentInput + amount)
    }

    func decrementOffer() {
        let currentInput = Double(userOfferInput) ?? currentHighestOffer
        if currentInput > 1 {
            userOfferInput = String(format: "%.0f", currentInput - 1)
        }
    }

    func decrementOffer(bySpecificAmount amount: Double) {
        let currentInput = Double(userOfferInput) ?? currentHighestOffer
        if currentInput > amount {
            userOfferInput = String(format: "%.0f", currentInput - amount)
        }
    }

    func sendPitch() {
        guard let newOffer = Double(userOfferInput), newOffer > 0 else { return }
        isPlacingOffer = true

        Task {
            do {
                let offerData: [String: Any] = [
                    "buyerID":       buyer.id,
                    "buyerName":     buyer.name,
                    "sellerID":      currentSellerID,
                    "sellerName":    currentSellerName,
                    "amount":        newOffer,
                    "status":        "pending",
                    "placedAt":      Timestamp(),
                    "isUrgentPitch": isUrgentPitch
                ]
                try await Firestore.firestore().collection("offers").addDocument(data: offerData)
                userOfferInput = ""
                isOutpitched = false
                scheduleNewOfferNotification(amount: newOffer)
            } catch {
                print("Error placing offer: \(error.localizedDescription)")
            }
            isPlacingOffer = false
        }
    }

    private func scheduleNewOfferNotification(amount: Double) {
        let buyerID = buyer.id
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = "New Offer Received!"
            content.body  = "\(self.currentSellerName) pitched Rs \(String(format: "%.0f", amount)) to you. Review it in Activity → Offers."
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: "newoffer-\(buyerID)-\(Date().timeIntervalSince1970)",
                content: content, trigger: nil
            )
            UNUserNotificationCenter.current().add(request) { error in  //call new offer notifcation 
                if let error { print("New offer notification error: \(error.localizedDescription)") }
            }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func scheduleOutpitchedNotification(newAmount: Double, sellerName: String) {
        let buyerName = buyer.name
        let buyerID   = buyer.id
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = "You've Been Outpitched!"
            content.body  = "\(sellerName) offered Rs \(String(format: "%.0f", newAmount)) to \(buyerName). Pitch higher to stay in."
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: "outpitched-\(buyerID)-\(Date().timeIntervalSince1970)",
                content: content, trigger: nil
            )
            UNUserNotificationCenter.current().add(request) { error in
                if let error { print("Notification error: \(error.localizedDescription)") }
            }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
