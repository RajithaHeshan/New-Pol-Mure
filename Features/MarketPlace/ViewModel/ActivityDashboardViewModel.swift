// Location: New-Pol-Mure/Features/MarketPlace/ViewModels/ActivityDashboardViewModel.swift

import SwiftUI
import FirebaseAuth
import FirebaseFirestore


private final class ActivityListenerBox {
    var listener: ListenerRegistration?
    init() {}
    deinit { listener?.remove() }
}

@Observable
@MainActor
class ActivityDashboardViewModel {

    var selectedTab: Int = 0

    // MARK: - Tab 0: Bids placed by this buyer
    var myBids: [Bid] = []

    // MARK: - Tab 1: Offers pitched TO this buyer by sellers
    var incomingOffers: [Offer] = []

    // MARK: - Tab 2: Financial transactions for this buyer
    var transactions: [Transaction] = []

    // MARK: - Tab 3: Contracts involving this buyer
    var contracts: [Contract] = []

    // MARK: - Highest bid per sellerID — drives winning/outbid status in tab 0
    var highestBidPerSeller: [String: Double] = [:]

    // MARK: - Loading States
    var isLoadingBids         = false
    var isLoadingOffers       = false
    var isLoadingTransactions = false
    var isLoadingContracts    = false

    private let currentBuyerID: String

    private let bidsListenerBox         = ActivityListenerBox()
    private let offersListenerBox       = ActivityListenerBox()
    private let transactionsListenerBox = ActivityListenerBox()
    private let contractsListenerBox    = ActivityListenerBox()

    // All bids listener to derive highest-per-seller winning status
    private let allBidsListenerBox = ActivityListenerBox()

    init() {
        self.currentBuyerID = Auth.auth().currentUser?.uid ?? ""
        attachBidsListener()
        attachAllBidsListener()
        attachOffersListener()
        attachTransactionsListener()
        attachContractsListener()
    }

    // MARK: - Tab 0: My Bids Listener
    private func attachBidsListener() {
        guard !currentBuyerID.isEmpty else { return }
        isLoadingBids = true

        bidsListenerBox.listener = Firestore.firestore()
            .collection("bids")
            .whereField("bidderID", isEqualTo: currentBuyerID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Bids listener error: \(error.localizedDescription)")
                    self.isLoadingBids = false
                    return
                }

                self.myBids = snapshot?.documents.compactMap {
                    Bid(id: $0.documentID, data: $0.data())
                }.sorted { $0.placedAt > $1.placedAt } ?? []

                self.isLoadingBids = false
            }
    }

    // MARK: - All Bids Listener (derives highest bid per seller for winning status)
    private func attachAllBidsListener() {
        allBidsListenerBox.listener = Firestore.firestore()
            .collection("bids")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }

                var map: [String: Double] = [:]
                for doc in docs {
                    let data = doc.data()
                    guard
                        let sellerID = data["sellerID"] as? String,
                        let amount   = data["amount"]   as? Double
                    else { continue }

                    if (map[sellerID] ?? 0) < amount {
                        map[sellerID] = amount
                    }
                }
                self.highestBidPerSeller = map
            }
    }

    // MARK: - Winning Status Helper
    func isWinning(bid: Bid) -> Bool {
        guard let highest = highestBidPerSeller[bid.sellerID] else { return false }
        return bid.amount >= highest
    }

    // MARK: - Tab 1: Incoming Offers Listener (sellers pitching to this buyer)
    private func attachOffersListener() {
        guard !currentBuyerID.isEmpty else { return }
        isLoadingOffers = true

        offersListenerBox.listener = Firestore.firestore()
            .collection("offers")
            .whereField("buyerID", isEqualTo: currentBuyerID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Offers listener error: \(error.localizedDescription)")
                    self.isLoadingOffers = false
                    return
                }

                self.incomingOffers = snapshot?.documents.compactMap {
                    Offer(id: $0.documentID, data: $0.data())
                }.sorted { $0.placedAt > $1.placedAt } ?? []

                self.isLoadingOffers = false
            }
    }

    // MARK: - Tab 2: Transactions Listener
    private func attachTransactionsListener() {
        guard !currentBuyerID.isEmpty else { return }
        isLoadingTransactions = true

        transactionsListenerBox.listener = Firestore.firestore()
            .collection("transactions")
            .whereField("buyerID", isEqualTo: currentBuyerID)
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
        guard !currentBuyerID.isEmpty else { return }
        isLoadingContracts = true

        contractsListenerBox.listener = Firestore.firestore()
            .collection("contracts")
            .whereField("buyerID", isEqualTo: currentBuyerID)
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
