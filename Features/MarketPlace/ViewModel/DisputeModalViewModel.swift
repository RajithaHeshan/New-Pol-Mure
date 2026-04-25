// Location: New-Pol-Mure/Features/Marketplace/ViewModels/DisputeModalViewModel.swift

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@Observable
@MainActor
class DisputeModalViewModel {

    // MARK: - Action States
    var isSubmitting  = false
    var isCancelling  = false
    var submitError: String? = nil
    var cancelError: String? = nil

    // MARK: - Constant Data
    let originalBid: Double
    let contractID: String
    let reasons = ["Quality (Rotten/Spoiled)", "Undersized Nuts", "Short Quantity", "Other"]

    init(contractID: String = "", originalBid: Double = 120.00) {
        self.contractID  = contractID
        self.originalBid = originalBid
    }

    // MARK: - Submit Counter-Offer
    func submitCounterOffer(
        reason: String,
        notes: String,
        counterOffer: String,
        onSuccess: @escaping @MainActor () -> Void
    ) {
        print("🟡 submitCounterOffer called — contractID: '\(contractID)', counterOffer: '\(counterOffer)'")
        let trimmed = counterOffer.trimmingCharacters(in: .whitespaces)
        guard let newAmount = Double(trimmed), newAmount > 0 else {
            print("❌ Validation failed — trimmed: '\(trimmed)', parsed: \(Double(trimmed) as Any?)")
            submitError = "Please enter a valid counter-offer amount greater than 0."
            return
        }
        guard !contractID.isEmpty else {
            print("❌ contractID is empty")
            submitError = "Contract ID is missing. Please try again."
            return
        }

        isSubmitting = true
        submitError  = nil

        print("🟡 Submitting dispute — contractID: \(contractID), counterOffer: \(newAmount)")

        let disputeData: [String: Any] = [
            "contractID":         contractID,
            "raisedByID":         Auth.auth().currentUser?.uid ?? "",
            "reason":             reason,
            "notes":              notes,
            "counterOfferAmount": newAmount,
            "originalAmount":     originalBid,
            "status":             "pending",
            "createdAt":          Timestamp()
        ]

        Task {
            do {
                let db = Firestore.firestore()

                try await db.collection("disputes").addDocument(data: disputeData)
                print("✅ Dispute document written")

                try await db.collection("contracts").document(contractID)
                    .updateData(["status": "dispute"])
                print("✅ Contract status → 'dispute'")

                isSubmitting = false
                onSuccess()
            } catch {
                print("❌ Submit dispute error: \(error.localizedDescription)")
                submitError  = error.localizedDescription
                isSubmitting = false
            }
        }
    }

    // MARK: - Cancel Contract Entirely
    func cancelContractEntirely(onSuccess: @escaping @MainActor () -> Void) {
        guard !contractID.isEmpty else { return }

        isCancelling = true
        cancelError  = nil

        Task {
            do {
                try await Firestore.firestore()
                    .collection("contracts")
                    .document(contractID)
                    .updateData(["status": "rejected"])
                print("✅ Contract cancelled")
                isCancelling = false
                onSuccess()
            } catch {
                print("❌ Cancel contract error: \(error.localizedDescription)")
                cancelError  = error.localizedDescription
                isCancelling = false
            }
        }
    }
}
