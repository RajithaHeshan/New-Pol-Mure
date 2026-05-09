

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


    var currentState: ContractState = .bidAccepted
    var isLocationRevealed = false
    var showDisputeModal   = false
    var isPulsing          = false
    var isDisputePending   = false   // true while seller hasn't responded yet

    
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
    let harvestName: String

    
    var buyerCoordinate:  CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
    var sellerCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609)

   
    var inspectionDate: Date = Date().addingTimeInterval(86400)

    
    var showDatePicker        = false
    var pendingPickerDate:    Date         = Date().addingTimeInterval(3600)   // default: 1 hour from now
    // Reminder offset in seconds — buyer selects how far ahead to be notified
    var selectedReminderOffset: TimeInterval = -3600  // default: 1 hour before

    // MARK: - Action States
    var isReleasingFunds = false

    // MARK: - Rating
    var showRatingSheet = false
    var buyerDisplayName: String = ""

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
        self.harvestName          = contract.harvestName

        self.currentState       = Self.mapStatus(contract.status)
        self.isDisputePending   = contract.status == "dispute"
        self.isLocationRevealed = contract.status == "inspection" || contract.status == "dispute" || contract.status == "qualityApproved" || contract.status == "payment" || contract.status == "completed"

       
       
       
        if let savedDate = contract.inspectionDate {
            self.inspectionDate    = savedDate
            self.pendingPickerDate = savedDate > Date() ? savedDate : Date().addingTimeInterval(3600) //don't espect inspection status
        }

       
        if let lat = contract.harvestLatitude, let lng = contract.harvestLongitude {
            self.sellerCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }

        fetchSellerProfile(sellerID: contract.sellerID, useProfileCoordinate: contract.harvestLatitude == nil)
        fetchBuyerCoordinate(buyerID: contract.buyerID)
        fetchBuyerDisplayName(buyerID: contract.buyerID)
        attachContractListener()

       
       //if buyer complete the contract can rate it 
        if contract.status == "completed" {
            checkIfAlreadyRated()
        }
    }

   
    private func attachContractListener() {
        contractListenerBox.listener = Firestore.firestore()
            .collection("contracts")
            .document(contractID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let data = snapshot?.data() else { return }

                if let status = data["status"] as? String {
                    withAnimation(.spring()) {
                        self.currentState       = Self.mapStatus(status)
                        self.isDisputePending   = status == "dispute"
                        self.isLocationRevealed = status == "inspection" || status == "dispute" || status == "qualityApproved" || status == "payment" || status == "completed"
                    }
                    // Show rating sheet when seller confirms handover and contract completes
                    if status == "completed" {
                        self.showRatingSheet = true
                        self.checkIfAlreadyRated()  // will set false if already rated
                    }
                }

               
                if let ts = data["inspectionDate"] as? Timestamp {
                    let stored = ts.dateValue()
                    self.inspectionDate    = stored
                    self.pendingPickerDate = stored > Date() ? stored : Date().addingTimeInterval(3600)
                }
            }
    }




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

    //escrow

    func lockFunds() {
        withAnimation(.spring()) { currentState = .fundsLocked }
        Task {
            try? await Firestore.firestore()
                .collection("contracts")
                .document(contractID)
                .updateData(["status": "fundsLocked"])
        }
    }

    
    //seller profile


    private func fetchSellerProfile(sellerID: String, useProfileCoordinate: Bool = true) {
        Task {
            let doc = try? await Firestore.firestore()
                .collection("users")
                .document(sellerID)
                .getDocument()
            guard let data = doc?.data() else { return }

            
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

    // Update Inspection Date 
    func updateInspectionDate(_ date: Date) {
        inspectionDate = date
        Task {
            try? await Firestore.firestore()
                .collection("contracts")
                .document(contractID)
                .updateData(["inspectionDate": Timestamp(date: date)])
        }
    }

    

    // Buyer approves quality — writes transactions and advances to qualityApproved.
    // Seller must then confirm handover to reach "completed".
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
                "harvestName":    harvestName,
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
                "harvestName":    harvestName,
                "source":         contractSource,
                "isCredit":       true,
                "completedAt":    now
            ]

            try? await db.collection("transactions").addDocument(data: buyerTx)
            try? await db.collection("transactions").addDocument(data: sellerTx)
            try? await db.collection("contracts").document(contractID)
                .updateData(["status": "qualityApproved"])

            isReleasingFunds = false
            // Rating sheet fires when the contract listener receives "completed" (after seller confirms handover)
        }
    }

    // Fetch buyer's display name for the rating sheet reviewer label
    private func fetchBuyerDisplayName(buyerID: String) {
        Task {
            let doc = try? await Firestore.firestore()
                .collection("users").document(buyerID).getDocument()
            if let name = doc?.data()?["fullName"] as? String {
                buyerDisplayName = name
            }
        }
    }

    // Check if buyer already rated this contract (prevents duplicate sheet on re-open)
    private func checkIfAlreadyRated() {
        Task {
            let snapshot = try? await Firestore.firestore()
                .collection("ratings")
                .whereField("contractID", isEqualTo: contractID)
                .whereField("reviewerID", isEqualTo: buyerID)
                .getDocuments()
            // If a rating already exists, don't show the sheet again
            if snapshot?.documents.isEmpty == false {
                showRatingSheet = false
            }
        }
    }
}
