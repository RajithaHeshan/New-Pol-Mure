
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

   
    var selectedTab: Int = 0

    
    var myOffers: [Offer] = []

   
    var incomingBids: [Bid] = []

   
    var transactions: [Transaction] = []

   
    var contracts: [Contract] = []

    
    var highestOfferPerBuyer: [String: Double] = [:]

    
    var isLoadingOffers       = false
    var isLoadingBids         = false
    var isLoadingTransactions = false
    var isLoadingContracts    = false

    private var currentSellerID: String { AuthManager.shared.currentUserID }

    private let offersListenerBox       = SellerActivityListenerBox()
    private let allOffersListenerBox   = SellerActivityListenerBox()
    private let bidsListenerBox        = SellerActivityListenerBox()
    private let transactionsListenerBox = SellerActivityListenerBox()
    private let contractsListenerBox   = SellerActivityListenerBox()

    init() {
        loadCachedData()
        startListeners()
    }

    private func startListeners(retryCount: Int = 0) {
        guard !currentSellerID.isEmpty else {
            guard retryCount < 5 else { return }
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                startListeners(retryCount: retryCount + 1)
            }
            return
        }
        attachOffersListener()
        attachAllOffersListener()
        attachBidsListener()
        attachTransactionsListener()
        attachContractsListener()
    }

    private func loadCachedData() {
        guard !currentSellerID.isEmpty else { return }
        let cache = CoreDataCache.shared
        let cachedOffers = cache.loadOffers(ownerID: currentSellerID)
        if !cachedOffers.isEmpty { myOffers = cachedOffers }
        let cachedBids = cache.loadBids(ownerID: currentSellerID)
        if !cachedBids.isEmpty { incomingBids = cachedBids }
        let cachedTx = cache.loadTransactions(ownerID: currentSellerID)
        if !cachedTx.isEmpty { transactions = cachedTx }
        let cachedContracts = cache.loadContracts(ownerID: currentSellerID)
        if !cachedContracts.isEmpty { contracts = cachedContracts }
    }



    private func attachOffersListener() {
        guard !currentSellerID.isEmpty else { return }
        isLoadingOffers = true

        offersListenerBox.listener = Firestore.firestore()
            .collection("offers")
            .whereField("sellerID", isEqualTo: currentSellerID)
            .whereField("status", in: ["pending", "declined"])
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Offers listener error: \(error.localizedDescription)")
                    self.isLoadingOffers = false
                    return
                }

                // Show ALL pitches sorted newest first — no deduplication
                // Each pitch shows its own date/time and winning status independently
                self.myOffers = snapshot?.documents.compactMap {
                    Offer(id: $0.documentID, data: $0.data())
                }.sorted { $0.placedAt > $1.placedAt } ?? []

                CoreDataCache.shared.saveOffers(self.myOffers, ownerID: self.currentSellerID)
                self.isLoadingOffers = false
            }
    }

  
  //urgent posts
  
    private func attachAllOffersListener() {
        allOffersListenerBox.listener = Firestore.firestore()
            .collection("offers")
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }

                // Key: "buyerID_urgent" or "buyerID_normal" — urgent and normal pitches
                // to the same buyer are separate competitions and must not cross-contaminate
                var map: [String: Double] = [:]
                for doc in docs {
                    let data = doc.data()
                    guard
                        let buyerID  = data["buyerID"]  as? String,
                        let amount   = data["amount"]   as? Double
                    else { continue }
                    let isUrgent = data["isUrgentPitch"] as? Bool ?? false
                    let key = buyerID + (isUrgent ? "_urgent" : "_normal")
                    if (map[key] ?? 0) < amount {
                        map[key] = amount
                    }
                }
                self.highestOfferPerBuyer = map
            }
    }

    // MARK: - Winning Status Helper (seller wins when their offer is the highest in its bucket)
    func isHighest(offer: Offer) -> Bool {
        let key = offer.buyerID + (offer.isUrgentPitch ? "_urgent" : "_normal")
        guard let highest = highestOfferPerBuyer[key] else { return false }
        return offer.amount >= highest
    }

   
    private func attachBidsListener() {
        guard !currentSellerID.isEmpty else { return }
        isLoadingBids = true

        bidsListenerBox.listener = Firestore.firestore()
            .collection("bids")
            .whereField("sellerID", isEqualTo: currentSellerID)
            .whereField("status", in: ["pending", "accepted"])
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

              
                if !self.incomingBids.isEmpty {
                    let existingIDs = Set(self.incomingBids.map { $0.id })
                    for bid in updated where !existingIDs.contains(bid.id) && bid.status == "pending" {
                        self.scheduleNewBidNotification(bid: bid)
                    }
                }

                self.incomingBids = updated
                CoreDataCache.shared.saveBids(updated, ownerID: self.currentSellerID)
                self.isLoadingBids = false
            }
    }

   

    // MARK: - Accept bid and create contract
    func acceptBid(_ bid: Bid) {
        let db = Firestore.firestore()
        let sellerID = currentSellerID

        guard !sellerID.isEmpty, !bid.id.isEmpty else { return }

        Task {
            // 1. Mark this bid accepted
            do {
                try await db.collection("bids").document(bid.id)
                    .updateData(["status": "accepted"])
            } catch {
                print("acceptBid failed: \(error.localizedDescription)")
                return
            }

            // 2. Fetch seller profile for contract
            let sellerDoc = try? await db.collection("users").document(sellerID).getDocument()
            let sellerName = sellerDoc?.data()?["fullName"] as? String ?? ""

            // 3. Build contract data
            let contractRef = "#\(Int.random(in: 1000...9999))"
            var contractData: [String: Any] = [
                "contractRef": contractRef,
                "buyerID":     bid.bidderID,
                "buyerName":   bid.bidderName,
                "sellerID":    sellerID,
                "sellerName":  sellerName,
                "status":      "escrow",
                "amount":      bid.amount,
                "source":      "bid",
                "createdAt":   Timestamp()
            ]

            if !bid.harvestID.isEmpty {
                let harvestDoc = try? await db.collection("harvestLots").document(bid.harvestID).getDocument()
                if let data = harvestDoc?.data() {
                    if let lat = data["latitude"]  as? Double,
                       let lng = data["longitude"] as? Double {
                        contractData["harvestLatitude"]  = lat
                        contractData["harvestLongitude"] = lng
                    }
                    if let qty = data["quantity"]     as? Int    { contractData["quantity"]     = qty }
                    if let loc = data["locationName"] as? String { contractData["locationName"] = loc }
                }
            } else {
                if let yieldStr = sellerDoc?.data()?["typicalYield"] as? String {
                    let digits = yieldStr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                    if let qty = Int(digits) { contractData["quantity"] = qty }
                }
                if let loc = sellerDoc?.data()?["locationName"] as? String {
                    contractData["locationName"] = loc
                }
            }

            // 4. Create contract
            do {
                try await db.collection("contracts").addDocument(data: contractData)
            } catch {
                print("acceptBid contract creation failed: \(error.localizedDescription)")
            }
        }
    }

    func declineBid(_ bid: Bid) {
        guard !bid.id.isEmpty else { return }
        Task {
            try? await Firestore.firestore()
                .collection("bids")
                .document(bid.id)
                .updateData(["status": "declined"])
        }
    }

    // MARK: - Delete Pitch/Offer (only pending or declined)
    func deletePitch(_ offer: Offer) {
        guard offer.status == "pending" || offer.status == "declined" else { return }
        Task {
            do {
                try await Firestore.firestore().collection("offers").document(offer.id).delete()
            } catch {
                print("Delete pitch error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Delete Transaction (local hide only — kept in Firestore for audit)
    func deleteTransaction(at offsets: IndexSet) {
        transactions.remove(atOffsets: offsets)
        CoreDataCache.shared.saveTransactions(transactions, ownerID: currentSellerID)
    }

    // MARK: - Delete Contract (only completed or rejected)
    func deleteContract(_ contract: Contract) {
        guard contract.status == "completed" || contract.status == "rejected" else { return }
        Task {
            do {
                try await Firestore.firestore().collection("contracts").document(contract.id).delete()
            } catch {
                print("Delete contract error: \(error.localizedDescription)")
            }
        }
    }

   
   //bids alert for sellers 

    private func scheduleNewBidNotification(bid: Bid) {
        let title = "New Bid on Your Harvest!"
        let body  = "\(bid.bidderName) placed Rs \(String(format: "%.0f", bid.amount)). Tap to Accept or Decline in Activity → Direct Bids."

        Task { @MainActor in
            NotificationStore.shared.add(ownerID: currentSellerID, title: title, body: body, type: "bid")
        }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body  = body
            content.sound = .default
            let request = UNNotificationRequest(identifier: "inbound-bid-\(bid.id)", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                if let error { print("Inbound bid notification error: \(error.localizedDescription)") }
            }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    
    private func attachTransactionsListener() {
        guard !currentSellerID.isEmpty else { return }
        isLoadingTransactions = true

        transactionsListenerBox.listener = Firestore.firestore()
            .collection("transactions")
            .whereField("sellerID", isEqualTo: currentSellerID)
            .whereField("isCredit", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Transactions listener error: \(error.localizedDescription)")
                    self.isLoadingTransactions = false
                    return
                }

                self.transactions = snapshot?.documents.compactMap {
                    Transaction(id: $0.documentID, data: $0.data())
                }.sorted { $0.completedAt > $1.completedAt } ?? []

                CoreDataCache.shared.saveTransactions(self.transactions, ownerID: self.currentSellerID)
                self.isLoadingTransactions = false
            }
    }

  
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

                CoreDataCache.shared.saveContracts(self.contracts, ownerID: self.currentSellerID)
                self.isLoadingContracts = false
            }
    }


}
