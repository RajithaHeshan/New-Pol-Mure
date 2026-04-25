// Location: New-Pol-Mure/Features/MarketPlace/ViewModels/SellerActivityDashboardViewModel.swift

import SwiftUI
import FirebaseFirestore
import UserNotifications


private final class SellerActivityListenerBox {
    var listener: ListenerRegistration?
    init() {}
    deinit { listener?.remove() }
}

@Observable
@MainActor
class SellerActivityDashboardViewModel {

    // UI State (Defaulting to 0 so the first tab opens automatically)
    var selectedTab: Int = 0

    // MARK: - Tab 0: Active Pitches placed by this seller
    var myOffers: [Offer] = []

    // MARK: - Tab 1: Direct Bids inbound on this seller's harvest lots
    var incomingBids: [Bid] = []

    // MARK: - Tab 2: Financial transactions for this seller
    var transactions: [Transaction] = []

    // MARK: - Tab 3: Contracts involving this seller
    var contracts: [Contract] = []

    // MARK: - Lowest offer per buyerID — drives winning/underbid status in tab 0
    var lowestOfferPerBuyer: [String: Double] = [:]

    // MARK: - Urgent buyer IDs — cross-referenced from urgentRequests collection
    var urgentBuyerIDs: Set<String> = []

    // MARK: - Loading States
    var isLoadingOffers       = false
    var isLoadingBids         = false
    var isLoadingTransactions = false
    var isLoadingContracts    = false

    private let currentSellerID: String

    private let offersListenerBox         = SellerActivityListenerBox()
    private let allOffersListenerBox      = SellerActivityListenerBox()
    private let bidsListenerBox           = SellerActivityListenerBox()
    private let transactionsListenerBox   = SellerActivityListenerBox()
    private let contractsListenerBox      = SellerActivityListenerBox()
    private let urgentRequestsListenerBox = SellerActivityListenerBox()

    init() {
        self.currentSellerID = AuthManager.shared.currentUserID
        attachOffersListener()
        attachAllOffersListener()
        attachBidsListener()
        attachTransactionsListener()
        attachContractsListener()
        attachUrgentRequestsListener()
    }

    // MARK: - Tab 0: My Offers Listener
    private func attachOffersListener() {
        guard !currentSellerID.isEmpty else { return }
        isLoadingOffers = true

        offersListenerBox.listener = Firestore.firestore()
            .collection("offers")
            .whereField("sellerID", isEqualTo: currentSellerID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Offers listener error: \(error.localizedDescription)")
                    self.isLoadingOffers = false
                    return
                }

                self.myOffers = snapshot?.documents.compactMap {
                    Offer(id: $0.documentID, data: $0.data())
                }.sorted { $0.placedAt > $1.placedAt } ?? []

                self.isLoadingOffers = false
            }
    }

    // MARK: - All Offers Listener (derives lowest offer per buyer for winning status)
    private func attachAllOffersListener() {
        allOffersListenerBox.listener = Firestore.firestore()
            .collection("offers")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }

                // Keep the lowest offer amount per buyerID across all sellers
                var map: [String: Double] = [:]
                for doc in docs {
                    let data = doc.data()
                    guard
                        let buyerID = data["buyerID"] as? String,
                        let amount  = data["amount"]  as? Double
                    else { continue }

                    if (map[buyerID] ?? .infinity) > amount {
                        map[buyerID] = amount
                    }
                }
                self.lowestOfferPerBuyer = map
            }
    }

    // MARK: - Winning Status Helper (seller wins when their offer is the lowest)
    func isLowest(offer: Offer) -> Bool {
        guard let lowest = lowestOfferPerBuyer[offer.buyerID] else { return false }
        return offer.amount <= lowest
    }

    // MARK: - Urgent Status Helper (buyer has an active urgent request)
    func isUrgent(offer: Offer) -> Bool {
        urgentBuyerIDs.contains(offer.buyerID)
    }

    // MARK: - Urgent Requests Listener (tracks which buyers have active urgent posts)
    private func attachUrgentRequestsListener() {
        urgentRequestsListenerBox.listener = Firestore.firestore()
            .collection("urgentRequests")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("UrgentRequests listener error (activity): \(error.localizedDescription)")
                    return
                }
                self.urgentBuyerIDs = Set(
                    snapshot?.documents.compactMap { $0.data()["buyerID"] as? String } ?? []
                )
            }
    }

    // MARK: - Tab 1: Inbound Bids on This Seller's Harvest Lots
    private func attachBidsListener() {
        guard !currentSellerID.isEmpty else { return }
        isLoadingBids = true

        bidsListenerBox.listener = Firestore.firestore()
            .collection("bids")
            .whereField("sellerID", isEqualTo: currentSellerID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Bids listener error: \(error.localizedDescription)")
                    self.isLoadingBids = false
                    return
                }

                let updated = snapshot?.documents.compactMap {
                    Bid(id: $0.documentID, data: $0.data())
                }.sorted { $0.placedAt > $1.placedAt } ?? []

                // Fire notification only for genuinely new pending bids (not on first load)
                if !self.incomingBids.isEmpty {
                    let existingIDs = Set(self.incomingBids.map { $0.id })
                    for bid in updated where !existingIDs.contains(bid.id) && bid.status == "pending" {
                        self.scheduleNewBidNotification(bid: bid)
                    }
                }

                self.incomingBids = updated
                self.isLoadingBids = false
            }
    }

    // MARK: - Accept Bid → creates a Contract and marks bid accepted
    func acceptBid(_ bid: Bid) {
        let db = Firestore.firestore()

        Task {
            do {
                // Mark the bid as accepted
                try await db.collection("bids").document(bid.id)
                    .updateData(["status": "accepted"])

                // Fetch seller name for the contract record
                let sellerDoc = try? await db.collection("users").document(currentSellerID).getDocument()
                let sellerName = sellerDoc?.data()?["fullName"] as? String ?? ""

                // Create a contract in escrow
                let contractRef = "#\(Int.random(in: 1000...9999))"
                let contractData: [String: Any] = [
                    "contractRef": contractRef,
                    "buyerID":     bid.bidderID,
                    "buyerName":   bid.bidderName,
                    "sellerID":    currentSellerID,
                    "sellerName":  sellerName,
                    "status":      "escrow",
                    "amount":      bid.amount,
                    "createdAt":   Timestamp()
                ]
                try await db.collection("contracts").addDocument(data: contractData)

            } catch {
                print("Accept bid error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Decline Bid → marks bid declined
    func declineBid(_ bid: Bid) {
        Task {
            do {
                try await Firestore.firestore()
                    .collection("bids")
                    .document(bid.id)
                    .updateData(["status": "declined"])
            } catch {
                print("Decline bid error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Local Push Notification (Inbound Bid Alert for Seller)
    private func scheduleNewBidNotification(bid: Bid) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            let content = UNMutableNotificationContent()
            content.title = "New Bid on Your Harvest!"
            content.body  = "\(bid.bidderName) placed Rs \(String(format: "%.0f", bid.amount)). Tap to Accept or Decline in Activity → Direct Bids."
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "inbound-bid-\(bid.id)",
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request) { error in
                if let error { print("Inbound bid notification error: \(error.localizedDescription)") }
            }
        }

        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    // MARK: - Tab 2: Transactions Listener
    private func attachTransactionsListener() {
        guard !currentSellerID.isEmpty else { return }
        isLoadingTransactions = true

        transactionsListenerBox.listener = Firestore.firestore()
            .collection("transactions")
            .whereField("sellerID", isEqualTo: currentSellerID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Transactions listener error: \(error.localizedDescription)")
                    self.isLoadingTransactions = false
                    return
                }

                self.transactions = snapshot?.documents.compactMap {
                    Transaction(id: $0.documentID, data: $0.data())
                }.sorted { $0.date > $1.date } ?? []

                self.isLoadingTransactions = false
            }
    }

    // MARK: - Tab 3: Contracts Listener
    private func attachContractsListener() {
        guard !currentSellerID.isEmpty else { return }
        isLoadingContracts = true

        contractsListenerBox.listener = Firestore.firestore()
            .collection("contracts")
            .whereField("sellerID", isEqualTo: currentSellerID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Contracts listener error: \(error.localizedDescription)")
                    self.isLoadingContracts = false
                    return
                }

                self.contracts = snapshot?.documents.compactMap {
                    Contract(id: $0.documentID, data: $0.data())
                }.sorted { $0.createdAt > $1.createdAt } ?? []

                self.isLoadingContracts = false
            }
    }

    // MARK: - Date Formatter Helper
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    // MARK: - Contract Status Display Helper
    func statusDisplayText(_ status: String) -> String {
        switch status {
        case "escrow":      return "Escrow Held"
        case "inspection":  return "Inspection Pending"
        case "completed":   return "Completed"
        case "rejected":    return "Rejected"
        default:            return status.capitalized
        }
    }
}
