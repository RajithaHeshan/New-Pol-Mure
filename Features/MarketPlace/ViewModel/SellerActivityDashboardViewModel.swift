// Location: New-Pol-Mure/Features/MarketPlace/ViewModels/SellerActivityDashboardViewModel.swift

import SwiftUI
import FirebaseAuth
import FirebaseFirestore


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

    // MARK: - Loading States
    var isLoadingOffers       = false
    var isLoadingBids         = false
    var isLoadingTransactions = false
    var isLoadingContracts    = false

    private let currentSellerID: String

    private let offersListenerBox       = SellerActivityListenerBox()
    private let allOffersListenerBox    = SellerActivityListenerBox()
    private let bidsListenerBox         = SellerActivityListenerBox()
    private let transactionsListenerBox = SellerActivityListenerBox()
    private let contractsListenerBox    = SellerActivityListenerBox()

    init() {
        self.currentSellerID = Auth.auth().currentUser?.uid ?? ""
        attachOffersListener()
        attachAllOffersListener()
        attachBidsListener()
        attachTransactionsListener()
        attachContractsListener()
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

                self.incomingBids = snapshot?.documents.compactMap {
                    Bid(id: $0.documentID, data: $0.data())
                }.sorted { $0.placedAt > $1.placedAt } ?? []

                self.isLoadingBids = false
            }
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
