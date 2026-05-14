// Location: New-Pol-Mure/Features/Logistics/ViewModels/SellerContractViewModel.swift

import SwiftUI
import FirebaseFirestore
import CoreLocation

private final class SellerContractListenerBox {
    var listener: ListenerRegistration?
    init() {}
    deinit { listener?.remove() }
}

@Observable
@MainActor
class SellerContractViewModel {

  
    var currentState: SellerContractState = .escrowSecured

   
    var isDisputed      = false
    var counterOffer:   Double = 0
    var originalPrice:  Double = 0
    var disputeReason:  String = ""
    var disputeNotes:   String = ""

    
    let contractID:  String
    let contractRef: String
    let buyerName:   String
    let buyerID:     String
    let sellerID:    String
    let amount:      Double
    var inspectionDate:    Date = Date().addingTimeInterval(86400)

    
    var sellerCoordinate:   CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609)
    var sellerLocationName: String = ""

   
    var buyerVolume: String = ""

   
    var isConfirmingHandover = false
    var isCancellingContract = false
    var hasVerifiedQuality   = false   
    var hasReviewedDispute   = false   

 
    var showRatingSheet  = false
    var sellerDisplayName: String = ""

    private let contractListenerBox  = SellerContractListenerBox()
    private let disputeListenerBox   = SellerContractListenerBox()

    init(contract: Contract) {
        self.contractID  = contract.id
        self.contractRef = contract.contractRef
        self.buyerName   = contract.buyerName
        self.buyerID     = contract.buyerID
        self.sellerID    = contract.sellerID
        self.amount      = contract.amount
        self.originalPrice = contract.amount

      
        switch contract.status {
        case "escrow":          self.currentState = .escrowSecured
        case "fundsLocked":     self.currentState = .escrowSecured
        case "inspection":      self.currentState = .buyerEnRoute
        case "dispute":         self.currentState = .buyerEnRoute
        case "qualityApproved": self.currentState = .qualityApproved  // buyer approved — seller can confirm handover
        case "payment":         self.currentState = .qualityApproved
        case "completed":       self.currentState = .completed
        default:                self.currentState = .escrowSecured
        }

        if let savedDate = contract.inspectionDate {
            self.inspectionDate = savedDate
        }

        attachContractListener()
        attachDisputeListener()
        fetchSellerCoordinate(sellerID: contract.sellerID)
        fetchBuyerVolume(buyerID: contract.buyerID)
        fetchSellerDisplayName(sellerID: contract.sellerID)

        if contract.status == "completed" {
            checkIfAlreadyRated(sellerID: contract.sellerID)
        }
    }

    
    private func fetchSellerCoordinate(sellerID: String) {
        guard !sellerID.isEmpty else { return }
        Task {
            let doc = try? await Firestore.firestore()
                .collection("users")
                .document(sellerID)
                .getDocument()
            guard let data = doc?.data() else { return }
            if let lat = data["latitude"] as? Double,
               let lng = data["longitude"] as? Double {
                sellerCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            }
            if let locName = data["locationName"] as? String {
                sellerLocationName = locName
            }
        }
    }

   
    private func fetchBuyerVolume(buyerID: String) {
        guard !buyerID.isEmpty else { return }
        Task {
            let doc = try? await Firestore.firestore()
                .collection("users")
                .document(buyerID)
                .getDocument()
            guard let data = doc?.data() else { return }
            if let volume = data["typicalVolume"] as? String {
                buyerVolume = volume
            }
        }
    }

  
    private func attachContractListener() {
        contractListenerBox.listener = Firestore.firestore()
            .collection("contracts")
            .document(contractID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let data = snapshot?.data() else { return }

                if let error {
                    print("SellerContract listener error: \(error.localizedDescription)")
                    return
                }

                let status = data["status"] as? String ?? ""
                withAnimation {
                    switch status {
                    case "escrow":          self.currentState = .escrowSecured
                    case "fundsLocked":     self.currentState = .escrowSecured
                    case "inspection":      self.currentState = .buyerEnRoute
                    case "dispute":         self.currentState = .buyerEnRoute
                    case "qualityApproved": self.currentState = .qualityApproved  // buyer approved — unlock handover
                    case "payment":         self.currentState = .qualityApproved
                    case "completed":       self.currentState = .completed
                    default: break
                    }
                }

               
                if let ts = data["inspectionDate"] as? Timestamp {
                    self.inspectionDate = ts.dateValue()
                }
            }
    }

    
      private func attachDisputeListener() {
        disputeListenerBox.listener = Firestore.firestore()
            .collection("disputes")
            .whereField("contractID", isEqualTo: contractID)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Dispute listener error: \(error.localizedDescription)")
                    return
                }

               
                let doc = snapshot?.documents.max {
                    let a = ($0.data()["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
                    let b = ($1.data()["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
                    return a < b
                }
                if let doc {
                    let data = doc.data()
                    self.counterOffer  = data["counterOfferAmount"] as? Double ?? 0
                    self.originalPrice = data["originalAmount"]     as? Double ?? self.amount
                    self.disputeReason = data["reason"] as? String ?? ""
                    self.disputeNotes  = data["notes"]  as? String ?? ""
                    if !self.isDisputed {
                        self.hasReviewedDispute = false  // reset on each new dispute
                    }
                    self.isDisputed    = true
                } else {
                    self.isDisputed         = false
                    self.hasReviewedDispute = false
                    self.disputeReason      = ""
                    self.disputeNotes       = ""
                }
            }
    }




    func acceptNewPrice() {
        Task {
            do {
                let db = Firestore.firestore()

             
                try await db.collection("contracts").document(contractID)
                    .updateData(["amount": counterOffer])

               
                let disputes = try await db.collection("disputes")
                    .whereField("contractID", isEqualTo: contractID)
                    .whereField("status", isEqualTo: "pending")
                    .getDocuments()

                for doc in disputes.documents {
                    try await doc.reference.updateData(["status": "resolved"])
                }

               
                try await db.collection("contracts").document(contractID)
                    .updateData(["status": "inspection"])

                withAnimation { isDisputed = false }
            } catch {
                print("Accept new price error: \(error.localizedDescription)")
            }
        }
    }


 
    func cancelContract() {
        isCancellingContract = true
        Task {
            do {
                try await Firestore.firestore()
                    .collection("contracts")
                    .document(contractID)
                    .updateData(["status": "rejected"])
            } catch {
                print("Cancel contract error: \(error.localizedDescription)")
            }
            isCancellingContract = false
        }
    }


    //confirmed handover escrow released 

    func confirmHandover() {
        isConfirmingHandover = true
        Task {
            do {
                let db = Firestore.firestore()

              
                try await db.collection("contracts").document(contractID)
                    .updateData(["status": "payment"])

                withAnimation { currentState = .qualityApproved }


                try? await Task.sleep(nanoseconds: 2_500_000_000)

                try await db.collection("contracts").document(contractID)
                    .updateData(["status": "completed"])

                withAnimation(.spring()) { currentState = .completed }

                checkIfAlreadyRated(sellerID: sellerID)
                showRatingSheet = true
            } catch {
                print("Confirm handover error: \(error.localizedDescription)")
            }
            isConfirmingHandover = false
        }
    }



    private func fetchSellerDisplayName(sellerID: String) {
        Task {
            let doc = try? await Firestore.firestore()
                .collection("users").document(sellerID).getDocument()
            if let name = doc?.data()?["fullName"] as? String {
                sellerDisplayName = name
            }
        }
    }

   
    private func checkIfAlreadyRated(sellerID: String) {
        Task {
            let snapshot = try? await Firestore.firestore()
                .collection("ratings")
                .whereField("contractID", isEqualTo: contractID)
                .whereField("reviewerID", isEqualTo: sellerID)
                .getDocuments()
            if snapshot?.documents.isEmpty == false {
                showRatingSheet = false
            }
        }
    }
}
