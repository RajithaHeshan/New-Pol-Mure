// Location: New-Pol-Mure/Features/MarketPlace/ViewModels/LiveOfferViewModel.swift

import SwiftUI
import MapKit
import FirebaseAuth
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

    // UI State
    var userOfferInput: String = ""
    var currentLowestOffer: Double
    var currentLowestSellerID: String = ""
    var isUndercut: Bool = false
    var isPlacingOffer: Bool = false

    // Current seller identity
    private let currentSellerID: String
    private var currentSellerName: String = ""

    private let listenerBox = OfferListenerBox()

    init(buyer: RegisteredBuyer, currentMarketPrice: Double = 120.0) {
        self.buyer = buyer
        self.currentLowestOffer = currentMarketPrice
        self.currentSellerID = Auth.auth().currentUser?.uid ?? ""
        fetchSellerName()
        attachOffersListener()
    }

    // MARK: - Fetch Seller Name from Firestore (fullName saved during registration)
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

    // MARK: - Real-Time Offers Listener
    private func attachOffersListener() {
        listenerBox.listener = Firestore.firestore()
            .collection("offers")
            .whereField("buyerID", isEqualTo: buyer.id)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Offers listener error: \(error.localizedDescription)")
                    return
                }

                let allOffers = snapshot?.documents.compactMap {
                    Offer(id: $0.documentID, data: $0.data())
                } ?? []

                // No offers yet — keep the market price default
                guard let lowestOffer = allOffers.sorted(by: { $0.amount < $1.amount }).first else {
                    return
                }

                let previousLeaderID = self.currentLowestSellerID

                // Always update the displayed price on every snapshot
                self.currentLowestOffer    = lowestOffer.amount
                self.currentLowestSellerID = lowestOffer.sellerID

                // We are now the lowest — clear any existing undercut warning
                if lowestOffer.sellerID == self.currentSellerID {
                    self.isUndercut = false
                    return
                }

                // Only alert if this seller has already placed at least one offer
                // AND the leader just changed to someone else
                let thisSellerHasOffer = allOffers.contains { $0.sellerID == self.currentSellerID }
                if thisSellerHasOffer && lowestOffer.sellerID != previousLeaderID {
                    self.isUndercut = true
                    self.scheduleUndercutNotification(
                        newAmount: lowestOffer.amount,
                        sellerName: lowestOffer.sellerName
                    )
                }
            }
    }

    // MARK: - Pitching Logic
    func incrementOffer(by amount: Double) {
        let currentInput = Double(userOfferInput) ?? currentLowestOffer
        userOfferInput = String(format: "%.0f", currentInput + amount)
    }

    func decrementOffer() {
        let currentInput = Double(userOfferInput) ?? currentLowestOffer
        if currentInput > 1 {
            userOfferInput = String(format: "%.0f", currentInput - 1)
        }
    }

    func decrementOffer(bySpecificAmount amount: Double) {
        let currentInput = Double(userOfferInput) ?? currentLowestOffer
        if currentInput > amount {
            userOfferInput = String(format: "%.0f", currentInput - amount)
        }
    }

    // MARK: - Send Offer to Firestore
    func sendPitch() {
        guard let newOffer = Double(userOfferInput), newOffer > 0 else { return }
        isPlacingOffer = true

        Task {
            do {
                let offerData: [String: Any] = [
                    "buyerID":    buyer.id,
                    "sellerID":   currentSellerID,
                    "sellerName": currentSellerName,
                    "amount":     newOffer,
                    "placedAt":   Timestamp()
                ]
                try await Firestore.firestore().collection("offers").addDocument(data: offerData)
                userOfferInput = ""
                isUndercut = false
            } catch {
                print("Error placing offer: \(error.localizedDescription)")
            }
            isPlacingOffer = false
        }
    }

    // MARK: - Local Push Notification (Undercut Alert)
    private func scheduleUndercutNotification(newAmount: Double, sellerName: String) {
        let buyerName = buyer.name
        let buyerID   = buyer.id

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("Notifications not authorized — status: \(settings.authorizationStatus.rawValue)")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "You've Been Undercut!"
            content.body  = "\(sellerName) offered Rs \(String(format: "%.0f", newAmount)) to \(buyerName). Pitch lower to stay in."
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "undercut-\(buyerID)-\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("Notification error: \(error.localizedDescription)")
                } else {
                    print("Undercut notification scheduled for \(sellerName)")
                }
            }
        }

        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    // MARK: - Debug / Simulation
    func simulateCheaperOffer() {
        let simulatedAmount = currentLowestOffer - 5.0
        currentLowestOffer = simulatedAmount
        currentLowestSellerID = "simulated-other-seller"
        isUndercut = true
        scheduleUndercutNotification(newAmount: simulatedAmount, sellerName: "Test Seller")
    }
}

