import Testing
import Foundation
import CoreLocation
import FirebaseFirestore
@testable import New_Pol_Mure

// MARK: - Bid Model Tests
struct BidModelTests {

    @Test func bidInitSucceedsWithValidData() {
        let data: [String: Any] = [
            "bidderID":   "buyer123",
            "bidderName": "Heshan",
            "amount":     4500.0,
            "placedAt":   Timestamp(date: Date()),
            "sellerID":   "seller456",
            "sellerName": "Kamal",
            "harvestID":  "harvest789",
            "status":     "pending"
        ]
        let bid = Bid(id: "bid001", data: data)
        #expect(bid != nil)
        #expect(bid?.bidderID   == "buyer123")
        #expect(bid?.bidderName == "Heshan")
        #expect(bid?.amount     == 4500.0)
        #expect(bid?.status     == "pending")
        #expect(bid?.sellerID   == "seller456")
    }

    @Test func bidInitFailsWhenAmountMissing() {
        let data: [String: Any] = [
            "bidderID":   "buyer123",
            "bidderName": "Heshan",
            "placedAt":   Timestamp(date: Date())
            // amount missing
        ]
        #expect(Bid(id: "bid002", data: data) == nil)
    }

    @Test func bidInitFailsWhenBidderIDMissing() {
        let data: [String: Any] = [
            "bidderName": "Heshan",
            "amount":     3000.0,
            "placedAt":   Timestamp(date: Date())
        ]
        #expect(Bid(id: "bid003", data: data) == nil)
    }

    @Test func bidDefaultsStatusToPendingWhenMissing() {
        let data: [String: Any] = [
            "bidderID":   "buyer123",
            "bidderName": "Heshan",
            "amount":     2000.0,
            "placedAt":   Timestamp(date: Date())
        ]
        let bid = Bid(id: "bid004", data: data)
        #expect(bid?.status == "pending")
    }

    @Test func bidDefaultsSellerNameToEmptyWhenMissing() {
        let data: [String: Any] = [
            "bidderID":   "buyer123",
            "bidderName": "Heshan",
            "amount":     2000.0,
            "placedAt":   Timestamp(date: Date())
        ]
        let bid = Bid(id: "bid005", data: data)
        #expect(bid?.sellerName == "")
    }
}

// MARK: - Offer Model Tests
struct OfferModelTests {

    @Test func offerInitSucceedsWithValidData() {
        let data: [String: Any] = [
            "buyerID":      "buyer123",
            "buyerName":    "Heshan",
            "sellerID":     "seller456",
            "sellerName":   "Kamal",
            "amount":       6000.0,
            "placedAt":     Timestamp(date: Date()),
            "status":       "pending",
            "isUrgentPitch": false
        ]
        let offer = Offer(id: "offer001", data: data)
        #expect(offer != nil)
        #expect(offer?.buyerID    == "buyer123")
        #expect(offer?.sellerName == "Kamal")
        #expect(offer?.amount     == 6000.0)
        #expect(offer?.isUrgentPitch == false)
    }

    @Test func offerInitFailsWhenBuyerIDMissing() {
        let data: [String: Any] = [
            "sellerID":   "seller456",
            "sellerName": "Kamal",
            "amount":     6000.0,
            "placedAt":   Timestamp(date: Date())
        ]
        #expect(Offer(id: "offer002", data: data) == nil)
    }

    @Test func offerIsUrgentPitchDefaultsFalse() {
        let data: [String: Any] = [
            "buyerID":    "buyer123",
            "sellerID":   "seller456",
            "sellerName": "Kamal",
            "amount":     5000.0,
            "placedAt":   Timestamp(date: Date())
        ]
        let offer = Offer(id: "offer003", data: data)
        #expect(offer?.isUrgentPitch == false)
    }

    @Test func offerIsUrgentPitchTrueWhenSet() {
        let data: [String: Any] = [
            "buyerID":       "buyer123",
            "sellerID":      "seller456",
            "sellerName":    "Kamal",
            "amount":        5000.0,
            "placedAt":      Timestamp(date: Date()),
            "isUrgentPitch": true
        ]
        let offer = Offer(id: "offer004", data: data)
        #expect(offer?.isUrgentPitch == true)
    }
}

// MARK: - Contract Model Tests
struct ContractModelTests {

    private func validContractData() -> [String: Any] {
        [
            "contractRef": "#1234",
            "buyerID":     "buyer123",
            "buyerName":   "Heshan",
            "sellerID":    "seller456",
            "sellerName":  "Kamal",
            "status":      "escrow",
            "amount":      15000.0,
            "createdAt":   Timestamp(date: Date()),
            "quantity":    500,
            "locationName":"Kurunegala",
            "source":      "bid"
        ]
    }

    @Test func contractInitSucceedsWithValidData() {
        let contract = Contract(id: "c001", data: validContractData())
        #expect(contract != nil)
        #expect(contract?.contractRef == "#1234")
        #expect(contract?.status      == "escrow")
        #expect(contract?.amount      == 15000.0)
        #expect(contract?.quantity    == 500)
        #expect(contract?.source      == "bid")
    }

    @Test func contractInitFailsWhenContractRefMissing() {
        var data = validContractData()
        data.removeValue(forKey: "contractRef")
        #expect(Contract(id: "c002", data: data) == nil)
    }

    @Test func contractInitFailsWhenAmountMissing() {
        var data = validContractData()
        data.removeValue(forKey: "amount")
        #expect(Contract(id: "c003", data: data) == nil)
    }

    @Test func contractQuantityDefaultsZeroWhenMissing() {
        var data = validContractData()
        data.removeValue(forKey: "quantity")
        let contract = Contract(id: "c004", data: data)
        #expect(contract?.quantity == 0)
    }

    @Test func contractLocationNameDefaultsEmptyWhenMissing() {
        var data = validContractData()
        data.removeValue(forKey: "locationName")
        let contract = Contract(id: "c005", data: data)
        #expect(contract?.locationName == "")
    }

    @Test func contractSourceDefaultsBidWhenMissing() {
        var data = validContractData()
        data.removeValue(forKey: "source")
        let contract = Contract(id: "c006", data: data)
        #expect(contract?.source == "bid")
    }
}

// MARK: - Transaction Model Tests
struct TransactionModelTests {

    @Test func transactionNetAmountCreditSubtractsFee() {
        let data: [String: Any] = [
            "buyerID":        "buyer123",
            "sellerID":       "seller456",
            "amount":         10000.0,
            "transactionFee": 200.0,
            "isCredit":       true,
            "completedAt":    Timestamp(date: Date())
        ]
        let tx = Transaction(id: "tx001", data: data)
        #expect(tx?.netAmount == 9800.0)
    }

    @Test func transactionNetAmountDebitAddsFee() {
        let data: [String: Any] = [
            "buyerID":        "buyer123",
            "sellerID":       "seller456",
            "amount":         10000.0,
            "transactionFee": 200.0,
            "isCredit":       false,
            "completedAt":    Timestamp(date: Date())
        ]
        let tx = Transaction(id: "tx002", data: data)
        #expect(tx?.netAmount == 10200.0)
    }

    @Test func transactionInitFailsWhenAmountMissing() {
        let data: [String: Any] = [
            "buyerID":     "buyer123",
            "sellerID":    "seller456",
            "isCredit":    true,
            "completedAt": Timestamp(date: Date())
        ]
        #expect(Transaction(id: "tx003", data: data) == nil)
    }
}

// MARK: - RecommendationEngine.parseVolume Tests
struct ParseVolumeTests {

    @Test func parsesPlainNumber() {
        #expect(RecommendationEngine.parseVolume("5000") == 5000)
    }

    @Test func parsesKSuffix() {
        #expect(RecommendationEngine.parseVolume("10K") == 10000)
    }

    @Test func parsesKSuffixWithSpace() {
        #expect(RecommendationEngine.parseVolume("5 K") == 5000)
    }

    @Test func parsesRangeReturnsAverage() {
        // "5K - 10K" → average of 5000 and 10000 = 7500
        #expect(RecommendationEngine.parseVolume("5K - 10K") == 7500)
    }

    @Test func parsesNutsSuffix() {
        #expect(RecommendationEngine.parseVolume("3000 Nuts") == 3000)
    }

    @Test func parsesWithCommas() {
        #expect(RecommendationEngine.parseVolume("10,000") == 10000)
    }

    @Test func returnsZeroForEmptyString() {
        #expect(RecommendationEngine.parseVolume("") == 0)
    }

    @Test func returnsZeroForGarbageInput() {
        #expect(RecommendationEngine.parseVolume("N/A") == 0)
    }
}

// MARK: - RecommendationEngine Distance Tests
struct DistanceTests {

    @Test func distanceBetweenSamePointIsNearZero() {
        let coord = CLLocationCoordinate2D(latitude: 7.48, longitude: 80.36)
        let dist = RecommendationEngine.shared.distance(from: coord, to: coord)
        // CLLocation can return a small non-zero value for identical coordinates — allow up to 0.1 km
        #expect(dist < 0.1)
    }

    @Test func distanceKurunegalaToKandyIsApprox40km() {
        let kurunegala = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609)
        let kandy      = CLLocationCoordinate2D(latitude: 7.2906, longitude: 80.6337)
        let dist = RecommendationEngine.shared.distance(from: kurunegala, to: kandy)
        // Real distance ~37–42 km — allow ±10 km tolerance
        #expect(dist > 27 && dist < 52)
    }

    @Test func distanceIsPositiveAndReasonable() {
        let a = CLLocationCoordinate2D(latitude: 7.48, longitude: 80.36)
        let b = CLLocationCoordinate2D(latitude: 6.90, longitude: 79.85)
        let dist = RecommendationEngine.shared.distance(from: a, to: b)
        // Distance between two points in Sri Lanka should be positive and under 500 km
        #expect(dist > 0 && dist < 500)
    }
}

// MARK: - KeychainHelper Tests
struct KeychainHelperTests {

    @Test func saveAndLoadReturnsCorrectValue() {
        KeychainHelper.save("1234", forKey: "test.pin")
        let loaded = KeychainHelper.load(forKey: "test.pin")
        #expect(loaded == "1234")
        KeychainHelper.delete(forKey: "test.pin")
    }

    @Test func loadReturnsNilForMissingKey() {
        KeychainHelper.delete(forKey: "nonexistent.key")
        let loaded = KeychainHelper.load(forKey: "nonexistent.key")
        #expect(loaded == nil)
    }

    @Test func deleteRemovesStoredValue() {
        KeychainHelper.save("9999", forKey: "test.delete")
        KeychainHelper.delete(forKey: "test.delete")
        let loaded = KeychainHelper.load(forKey: "test.delete")
        #expect(loaded == nil)
    }

    @Test func overwriteUpdatesValue() {
        KeychainHelper.save("1111", forKey: "test.overwrite")
        KeychainHelper.save("2222", forKey: "test.overwrite")
        let loaded = KeychainHelper.load(forKey: "test.overwrite")
        #expect(loaded == "2222")
        KeychainHelper.delete(forKey: "test.overwrite")
    }
}
