import SwiftUI
import FirebaseFirestore
import UserNotifications


private final class ActivityListenerBox {
    var listener: ListenerRegistration?
    init() {}
    deinit { listener?.remove() }
}

@Observable
@MainActor
class ActivityDashboardViewModel {

    var selectedTab: Int = 0

   
    var myBids: [Bid] = []

   
    var incomingOffers: [Offer] = []


    var transactions: [Transaction] = []

  
    var contracts: [Contract] = []

  
    var highestBidPerSeller: [String: Double] = [:]

  
    var isLoadingBids         = false
    var isLoadingOffers       = false
    var isLoadingTransactions = false
    var isLoadingContracts    = false

    private var currentBuyerID: String { AuthManager.shared.currentUserID }

    private let bidsListenerBox         = ActivityListenerBox()
    private let offersListenerBox       = ActivityListenerBox()
    private let transactionsListenerBox = ActivityListenerBox()
    private let contractsListenerBox    = ActivityListenerBox()


    private let allBidsListenerBox = ActivityListenerBox()

    init() {
        loadCachedData()
        attachBidsListener()
        attachAllBidsListener()
        attachOffersListener()
        attachTransactionsListener()
        attachContractsListener()
    }


    private func loadCachedData() {
        guard !currentBuyerID.isEmpty else { return }
        let cache = CoreDataCache.shared
        let cachedBids = cache.loadBids(ownerID: currentBuyerID)
        if !cachedBids.isEmpty { myBids = cachedBids }
        let cachedOffers = cache.loadOffers(ownerID: currentBuyerID)
        if !cachedOffers.isEmpty { incomingOffers = cachedOffers }
        let cachedTx = cache.loadTransactions(ownerID: currentBuyerID)
        if !cachedTx.isEmpty { transactions = cachedTx }
        let cachedContracts = cache.loadContracts(ownerID: currentBuyerID)
        if !cachedContracts.isEmpty { contracts = cachedContracts }
   
    print("📦 CoreData loaded: bids=\(cachedBids.count) offers=\(cachedOffers.count) tx=\(cachedTx.count) contracts=\(cachedContracts.count)")
    }


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

                let bids = snapshot?.documents.compactMap {
                    Bid(id: $0.documentID, data: $0.data())
                }.sorted { $0.placedAt > $1.placedAt } ?? []

                Task {
                    self.myBids = await self.resolveSellerNames(for: bids)
                    CoreDataCache.shared.saveBids(self.myBids, ownerID: self.currentBuyerID)
                    self.isLoadingBids = false
                }
            }
    }

    
    private func resolveSellerNames(for bids: [Bid]) async -> [Bid] {
        let db = Firestore.firestore()
        // Collect unique sellerIDs that need a name lookup
        let needsLookup = Set(bids.filter { $0.sellerName.isEmpty && !$0.sellerID.isEmpty }.map { $0.sellerID })
        guard !needsLookup.isEmpty else { return bids }

        // Fetch all missing names in parallel
        var nameMap: [String: String] = [:]
        await withTaskGroup(of: (String, String).self) { group in  //ui fast even many bids. concurrent sellers
            for sellerID in needsLookup {
                group.addTask {
                    let doc = try? await db.collection("users").document(sellerID).getDocument()
                    let name = doc?.data()?["fullName"] as? String ?? ""
                    return (sellerID, name)
                }
            }
            for await (sellerID, name) in group {
                nameMap[sellerID] = name
            }
        }



       
        return bids.map { bid in
            guard bid.sellerName.isEmpty, let resolvedName = nameMap[bid.sellerID] else { return bid }
            return Bid(id: bid.id, data: [
                "sellerID":   bid.sellerID,
                "sellerName": resolvedName,
                "bidderID":   bid.bidderID,
                "bidderName": bid.bidderName,
                "harvestID":  bid.harvestID,
                "amount":     bid.amount,
                "status":     bid.status,
                "placedAt":   Timestamp(date: bid.placedAt)
            ]) ?? bid
        }
    }

  
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


   
    func isWinning(bid: Bid) -> Bool {
        guard let highest = highestBidPerSeller[bid.sellerID] else { return false }
        return bid.amount >= highest
    }

  
    private func attachOffersListener() {
        guard !currentBuyerID.isEmpty else { return }
        isLoadingOffers = true

        offersListenerBox.listener = Firestore.firestore()
            .collection("offers")
            .whereField("buyerID", isEqualTo: currentBuyerID) //related Buyerid
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Offers listener error: \(error.localizedDescription)")
                    self.isLoadingOffers = false
                    return
                }

                let updated = snapshot?.documents.compactMap {
                    Offer(id: $0.documentID, data: $0.data())
                }.sorted { $0.placedAt > $1.placedAt } ?? []

                
                if !self.incomingOffers.isEmpty {
                    let existingIDs = Set(self.incomingOffers.map { $0.id })
                    for offer in updated where !existingIDs.contains(offer.id) && offer.status == "pending" {
                        self.scheduleNewOfferNotification(offer: offer)
                    }
                }

                self.incomingOffers = updated
                CoreDataCache.shared.saveOffers(updated, ownerID: self.currentBuyerID)
                self.isLoadingOffers = false
            }
    }

 
    func acceptOffer(_ offer: Offer) {
        let db = Firestore.firestore()

        Task {
            do {

                try await db.collection("offers").document(offer.id)
                    .updateData(["status": "accepted"])


                let buyerDoc   = try? await db.collection("users").document(currentBuyerID).getDocument()
                let buyerName  = buyerDoc?.data()?["fullName"] as? String ?? ""


                let sellerDoc = try? await db.collection("users").document(offer.sellerID).getDocument()

                let contractRef = "#\(Int.random(in: 1000...9999))"
                var contractData: [String: Any] = [
                    "contractRef": contractRef,
                    "buyerID":     currentBuyerID,
                    "buyerName":   buyerName,
                    "sellerID":    offer.sellerID,
                    "sellerName":  offer.sellerName,
                    "status":      "escrow",
                    "amount":      offer.amount,
                    "source":      "offer",
                    "createdAt":   Timestamp()
                ]
                if let yield = sellerDoc?.data()?["typicalYield"] as? String,
                   let qty = Int(yield) { contractData["quantity"] = qty }
                if let loc = sellerDoc?.data()?["locationName"] as? String { contractData["locationName"] = loc }

                try await db.collection("contracts").addDocument(data: contractData)

            } catch {
                print("Accept offer error: \(error.localizedDescription)")
            }
        }
    }


    func declineOffer(_ offer: Offer) {
        Task {
            do {
                try await Firestore.firestore()
                    .collection("offers")
                    .document(offer.id)
                    .updateData(["status": "declined"])
            } catch {
                print("Decline offer error: \(error.localizedDescription)")
            }
        }
    }

  
    func deleteBid(_ bid: Bid) {
        guard bid.status == "pending" else { return }
        Task {
            do {
                try await Firestore.firestore().collection("bids").document(bid.id).delete()
            } catch {
                print("Delete bid error: \(error.localizedDescription)")
            }
        }
    }

   
    func deleteTransaction(at offsets: IndexSet) {
        transactions.remove(atOffsets: offsets)
        CoreDataCache.shared.saveTransactions(transactions, ownerID: currentBuyerID)
    }

   
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

  
    private func scheduleNewOfferNotification(offer: Offer) {
        let title = "New Pitch from a Seller!"
        let body  = "\(offer.sellerName) offered Rs \(String(format: "%.0f", offer.amount)). Tap to Accept or Decline in Activity → Offers."

        Task { @MainActor in
            NotificationStore.shared.add(ownerID: currentBuyerID, title: title, body: body, type: "offer")
        }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body  = body
            content.sound = .default
            let request = UNNotificationRequest(identifier: "inbound-offer-\(offer.id)", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                if let error { print("Inbound offer notification error: \(error.localizedDescription)") }
            }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }


    private func attachTransactionsListener() {
        guard !currentBuyerID.isEmpty else { return }
        isLoadingTransactions = true

        transactionsListenerBox.listener = Firestore.firestore()
            .collection("transactions")
            .whereField("buyerID", isEqualTo: currentBuyerID)
            .whereField("isCredit", isEqualTo: false)
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

                CoreDataCache.shared.saveTransactions(self.transactions, ownerID: self.currentBuyerID)
                self.isLoadingTransactions = false
            }
    }

  //contract 

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

                CoreDataCache.shared.saveContracts(self.contracts, ownerID: self.currentBuyerID)
                self.isLoadingContracts = false
            }
    }

   
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

 
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
