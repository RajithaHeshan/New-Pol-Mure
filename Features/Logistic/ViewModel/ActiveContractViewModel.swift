

import SwiftUI
import MapKit
import FirebaseFirestore


private final class ContractListenerBox {
    var listener: ListenerRegistration?
    init() {}
    deinit { listener?.remove() }
}

@Observable
@MainActor
class ActiveContractViewModel {

    // MARK: - FSM State
    var currentState: ContractState = .bidAccepted
    var isLocationRevealed = false
    var showDisputeModal   = false
    var isPulsing          = false

    // MARK: - Contract Identity (passed in from the Contracts list)
    let contractID:  String
    let contractRef: String
    let sellerName:  String
    let sellerID:    String
    let buyerID:     String
    let buyerName:   String
    let quantity:    Int
    let contractLocationName: String
    let contractSource: String  // "bid" or "offer"
    var sellerPhone:        String = ""
    var sellerLocationName: String = ""
    var sellerYield:        String = ""
    let amount:      Double

    // MARK: - Location (fetched from Firestore seller profile)
    var buyerCoordinate:  CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
    var sellerCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609)

    // Persisted in Firestore — written when buyer confirms inspection date
    var inspectionDate: Date = Date().addingTimeInterval(86400)

    // MARK: - Date Picker State (buyer chooses before revealing location)
    var showDatePicker        = false
    var pendingPickerDate:    Date         = Date().addingTimeInterval(3600)   // default: 1 hour from now
    // Reminder offset in seconds — buyer selects how far ahead to be notified
    var selectedReminderOffset: TimeInterval = -3600  // default: 1 hour before

    // MARK: - Action States
    var isReleasingFunds = false

    private let contractListenerBox = ContractListenerBox()

    init(contract: Contract) {
        self.contractID           = contract.id
        self.contractRef          = contract.contractRef
        self.sellerName           = contract.sellerName
        self.sellerID             = contract.sellerID
        self.buyerID              = contract.buyerID
        self.buyerName            = contract.buyerName
        self.quantity             = contract.quantity
        self.contractLocationName = contract.locationName
        self.contractSource       = contract.source
        self.amount               = contract.amount

        self.currentState       = Self.mapStatus(contract.status)
        self.isLocationRevealed = contract.status == "inspection" || contract.status == "dispute" || contract.status == "qualityApproved" || contract.status == "payment" || contract.status == "completed"

        if let savedDate = contract.inspectionDate {
            self.inspectionDate    = savedDate
            self.pendingPickerDate = savedDate > Date() ? savedDate : Date().addingTimeInterval(3600)
        }

        // If contract was from a harvest bid, seed the harvest's exact coordinates directly.
        // fetchSellerProfile will still run to get phone/yield, but won't overwrite coordinates.
        if let lat = contract.harvestLatitude, let lng = contract.harvestLongitude {
            self.sellerCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }

        fetchSellerProfile(sellerID: contract.sellerID, useProfileCoordinate: contract.harvestLatitude == nil)
        fetchBuyerCoordinate(buyerID: contract.buyerID)
        attachContractListener()
    }

    // MARK: - Real-Time Contract Listener
    private func attachContractListener() {
        contractListenerBox.listener = Firestore.firestore()
            .collection("contracts")
            .document(contractID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let data = snapshot?.data() else { return }

                if let status = data["status"] as? String {
                    withAnimation(.spring()) {
                        self.currentState       = Self.mapStatus(status)
                        self.isLocationRevealed = status == "inspection" || status == "dispute" || status == "qualityApproved" || status == "payment" || status == "completed"
                    }
                }

                // Sync inspection date — if stored date is in the past, reset to 1 hour from now
                if let ts = data["inspectionDate"] as? Timestamp {
                    let stored = ts.dateValue()
                    self.inspectionDate    = stored
                    self.pendingPickerDate = stored > Date() ? stored : Date().addingTimeInterval(3600)
                }
            }
    }

    // MARK: - Firestore status string → FSM state
    private static func mapStatus(_ status: String) -> ContractState {
        switch status {
        case "escrow":          return .bidAccepted
        case "fundsLocked":     return .fundsLocked
        case "inspection":      return .inspectionPending
        case "dispute":         return .inspectionPending
        case "qualityApproved": return .paymentPending
        case "payment":         return .paymentPending
        case "completed":       return .completed
        default:                return .bidAccepted
        }
    }

    // MARK: - Lock Funds → buyer confirms escrow, advances contract to fundsLocked
    func lockFunds() {
        withAnimation(.spring()) { currentState = .fundsLocked }
        Task {
            try? await Firestore.firestore()
                .collection("contracts")
                .document(contractID)
                .updateData(["status": "fundsLocked"])
        }
    }

    // MARK: - Fetch Seller Profile: phone, yield, and optionally coordinates
    // useProfileCoordinate = false when the contract already has harvest coordinates
    private func fetchSellerProfile(sellerID: String, useProfileCoordinate: Bool = true) {
        Task {
            let doc = try? await Firestore.firestore()
                .collection("users")
                .document(sellerID)
                .getDocument()
            guard let data = doc?.data() else { return }

            // Only overwrite sellerCoordinate with the seller's home location
            // when this is a direct registered-seller bid (not a harvest bid).
            if useProfileCoordinate,
               let lat = data["latitude"] as? Double,
               let lng = data["longitude"] as? Double {
                sellerCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            }
            if let phone = data["phone"] as? String {
                sellerPhone = phone
            }
            if let locName = data["locationName"] as? String {
                sellerLocationName = locName
            }
            if let yield = data["typicalYield"] as? String {
                sellerYield = yield
            }
        }
    }

    // MARK: - Fetch Buyer Coordinate for route origin
    private func fetchBuyerCoordinate(buyerID: String) {
        Task {
            let doc = try? await Firestore.firestore()
                .collection("users")
                .document(buyerID)
                .getDocument()
            guard let data = doc?.data() else { return }

            if let lat = data["latitude"] as? Double,
               let lng = data["longitude"] as? Double {
                buyerCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            }
        }
    }

    // MARK: - Reveal Location → buyer confirms chosen date, advances contract to inspection
    func revealLocation() {
        // Use the date the buyer selected in the picker
        inspectionDate = pendingPickerDate

        withAnimation { isLocationRevealed = true }

        Task {
            try? await Firestore.firestore()
                .collection("contracts")
                .document(contractID)
                .updateData([
                    "status":         "inspection",
                    "inspectionDate": Timestamp(date: pendingPickerDate)
                ])
        }
    }

    // MARK: - Update Inspection Date (called when buyer changes date after reveal)
    func updateInspectionDate(_ date: Date) {
        inspectionDate = date
        Task {
            try? await Firestore.firestore()
                .collection("contracts")
                .document(contractID)
                .updateData(["inspectionDate": Timestamp(date: date)])
        }
    }

    // MARK: - Approve Quality → advances contract and writes completed transactions for both parties
    func releaseFundsSimulation() {
        isReleasingFunds = true
        withAnimation { currentState = .paymentPending }

        Task {
            let db = Firestore.firestore()
            let now = Timestamp()
            let fee = amount * 0.02  // 2% platform fee
            let loc = contractLocationName.isEmpty ? sellerLocationName : contractLocationName
            let pricePerNut = quantity > 0 ? amount / Double(quantity) : amount

            // Buyer transaction — outgoing payment
            let buyerTx: [String: Any] = [
                "contractRef":    contractRef,
                "buyerID":        buyerID,
                "buyerName":      buyerName,
                "sellerID":       sellerID,
                "sellerName":     sellerName,
                "quantity":       quantity,
                "pricePerNut":    pricePerNut,
                "amount":         amount,
                "transactionFee": fee,
                "locationName":   loc,
                "source":         contractSource,
                "isCredit":       false,
                "completedAt":    now
            ]
            // Seller transaction — incoming payment
            let sellerTx: [String: Any] = [
                "contractRef":    contractRef,
                "buyerID":        buyerID,
                "buyerName":      buyerName,
                "sellerID":       sellerID,
                "sellerName":     sellerName,
                "quantity":       quantity,
                "pricePerNut":    pricePerNut,
                "amount":         amount,
                "transactionFee": fee,
                "locationName":   loc,
                "source":         contractSource,
                "isCredit":       true,
                "completedAt":    now
            ]

            try? await db.collection("transactions").addDocument(data: buyerTx)
            try? await db.collection("transactions").addDocument(data: sellerTx)
            try? await db.collection("contracts").document(contractID)
                .updateData(["status": "qualityApproved"])

            isReleasingFunds = false
        }
    }
}
