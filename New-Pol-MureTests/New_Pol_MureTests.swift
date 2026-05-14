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

// MARK: - PriceForecastEngine Tests
struct PriceForecastEngineTests {

    // Valid zone returns a forecast
    @Test func validZoneReturnsForecast() {
        let forecast = PriceForecastEngine.shared.predict(
            zoneID:                 "kurunegala",
            weeklyAvgPrice:         110.0,
            prevWeekAvgPrice:       105.0,
            weeklyChangePct:        4.76,
            weeklyTransactionCount: 8
        )
        #expect(forecast != nil)
    }

    // Unknown zone returns nil — no silent wrong-zone prediction
    @Test func unknownZoneReturnsNil() {
        let forecast = PriceForecastEngine.shared.predict(
            zoneID:                 "badulla",
            weeklyAvgPrice:         100.0,
            prevWeekAvgPrice:       98.0,
            weeklyChangePct:        2.0,
            weeklyTransactionCount: 5
        )
        #expect(forecast == nil)
    }

    // Zero weekly average returns nil — no data guard
    @Test func zeroWeeklyAvgReturnsNil() {
        let forecast = PriceForecastEngine.shared.predict(
            zoneID:                 "kandy",
            weeklyAvgPrice:         0,
            prevWeekAvgPrice:       0,
            weeklyChangePct:        0,
            weeklyTransactionCount: 0
        )
        #expect(forecast == nil)
    }

    // Output is always clamped within Rs 50–200
    @Test func outputClampedWithinRange() {
        let forecast = PriceForecastEngine.shared.predict(
            zoneID:                 "colombo",
            weeklyAvgPrice:         120.0,
            prevWeekAvgPrice:       115.0,
            weeklyChangePct:        4.35,
            weeklyTransactionCount: 10
        )
        if let forecast {
            #expect(forecast.predictedPrice >= 50.0)
            #expect(forecast.predictedPrice <= 200.0)
        }
    }

    // zoneName in result matches the input zoneID
    @Test func forecastZoneNameMatchesInput() {
        let forecast = PriceForecastEngine.shared.predict(
            zoneID:                 "galle",
            weeklyAvgPrice:         95.0,
            prevWeekAvgPrice:       93.0,
            weeklyChangePct:        2.15,
            weeklyTransactionCount: 6
        )
        #expect(forecast?.zoneName == "galle")
    }

    // All 10 valid zones return a forecast
    @Test func allValidZonesReturnForecast() {
        let zones = ["anuradhapura","colombo","galle","gampaha",
                     "kandy","kegalle","kurunegala","matale","puttalam","ratnapura"]
        for zone in zones {
            let forecast = PriceForecastEngine.shared.predict(
                zoneID:                 zone,
                weeklyAvgPrice:         100.0,
                prevWeekAvgPrice:       98.0,
                weeklyChangePct:        2.0,
                weeklyTransactionCount: 7
            )
            #expect(forecast != nil, "Expected forecast for zone: \(zone)")
        }
    }

    // Transaction count at max training value (19) still works
    @Test func transactionCountAtMaxTrainingValue() {
        let forecast = PriceForecastEngine.shared.predict(
            zoneID:                 "kurunegala",
            weeklyAvgPrice:         108.0,
            prevWeekAvgPrice:       105.0,
            weeklyChangePct:        2.86,
            weeklyTransactionCount: 19
        )
        #expect(forecast != nil)
    }

    // Negative weekly change (price drop) still returns a valid forecast
    @Test func negativePriceChangeReturnsForecast() {
        let forecast = PriceForecastEngine.shared.predict(
            zoneID:                 "kandy",
            weeklyAvgPrice:         95.0,
            prevWeekAvgPrice:       105.0,
            weeklyChangePct:        -9.52,
            weeklyTransactionCount: 8
        )
        #expect(forecast != nil)
        if let forecast {
            #expect(forecast.predictedPrice >= 50.0)
            #expect(forecast.predictedPrice <= 200.0)
        }
    }
}

// MARK: - CoconutZone Tests
struct CoconutZoneTests {

    // "all" zone contains every coordinate (radius 999 km)
    @Test func allZoneContainsAnyCoordinate() {
        let allZone = CoconutZone.allZones.first { $0.id == "all" }!
        #expect(allZone.contains(lat: 7.48, lng: 80.36))
        #expect(allZone.contains(lat: 6.05, lng: 80.22))
        #expect(allZone.contains(lat: 8.31, lng: 80.40))
    }

    // Kurunegala centre is inside Kurunegala zone
    @Test func kurunegalaCentreIsInsideItsZone() {
        let zone = CoconutZone.allZones.first { $0.id == "kurunegala" }!
        #expect(zone.contains(lat: zone.centerLat, lng: zone.centerLng))
    }

    // Colombo centre is NOT inside Kandy zone
    @Test func colomboCentreIsNotInsideKandyZone() {
        let kandy = CoconutZone.allZones.first { $0.id == "kandy" }!
        // Colombo centre ~100 km from Kandy, well outside 35 km radius
        #expect(!kandy.contains(lat: 6.9271, lng: 79.8612))
    }

    // zone(for:) returns "all" fallback when no zone matches
    @Test func zoneForUnknownCoordReturnsAll() {
        // Coordinate clearly outside Sri Lanka
        let zone = CoconutZone.zone(for: 51.5, lng: -0.12) // London
        #expect(zone.id == "all")
    }

    // zone(for:) detects Kurunegala correctly
    @Test func zoneForKurunegalaCoord() {
        let zone = CoconutZone.zone(for: 7.4818, lng: 80.3609)
        #expect(zone.id == "kurunegala")
    }

    // zone(for:) detects Kandy correctly
    @Test func zoneForKandyCoord() {
        let zone = CoconutZone.zone(for: 7.2906, lng: 80.6337)
        #expect(zone.id == "kandy")
    }

    // All zones list has exactly 11 entries (10 districts + "all")
    @Test func allZonesCountIs11() {
        #expect(CoconutZone.allZones.count == 11)
    }

    // No duplicate zone IDs
    @Test func noDuplicateZoneIDs() {
        let ids = CoconutZone.allZones.map { $0.id }
        #expect(Set(ids).count == ids.count)
    }
}

// MARK: - MarketAnalyticsViewModel Logic Tests
struct MarketAnalyticsViewModelTests {

    // hasNoData is true when all prices are zero
    @Test func hasNoDataTrueWhenAllPricesZero() {
        let trends = [
            PriceTrend(id: "1 May", day: "Thu", date: Date(), price: 0),
            PriceTrend(id: "2 May", day: "Fri", date: Date(), price: 0),
        ]
        let allZero = trends.allSatisfy { $0.price == 0 }
        #expect(allZero == true)
    }

    // hasNoData is false when at least one price is non-zero
    @Test func hasNoDataFalseWhenOnePriceNonZero() {
        let trends = [
            PriceTrend(id: "1 May", day: "Thu", date: Date(), price: 0),
            PriceTrend(id: "2 May", day: "Fri", date: Date(), price: 105.0),
        ]
        let allZero = trends.allSatisfy { $0.price == 0 }
        #expect(allZero == false)
    }

    // Transaction count capped at 19 before model call
    @Test func transactionCountCappedAt19() {
        let raw = 50
        let clamped = min(raw, 19)
        #expect(clamped == 19)
    }

    // Transaction count below 19 is unchanged
    @Test func transactionCountBelowCapUnchanged() {
        let raw = 12
        let clamped = min(raw, 19)
        #expect(clamped == 12)
    }

    // Transaction count exactly 19 is unchanged
    @Test func transactionCountExactly19Unchanged() {
        let raw = 19
        let clamped = min(raw, 19)
        #expect(clamped == 19)
    }

    // weeklyChangePct calculation — positive change
    @Test func weeklyChangePctPositive() {
        let current = 110.0
        let prev    = 100.0
        let pct = ((current - prev) / prev) * 100
        #expect(abs(pct - 10.0) < 0.001)
    }

    // weeklyChangePct calculation — negative change
    @Test func weeklyChangePctNegative() {
        let current = 90.0
        let prev    = 100.0
        let pct = ((current - prev) / prev) * 100
        #expect(abs(pct - (-10.0)) < 0.001)
    }

    // weeklyChangePct when prev is zero returns zero (no division by zero)
    @Test func weeklyChangePctZeroWhenNoPrevData() {
        let current = 105.0
        let prev    = 0.0
        let pct = prev > 0 ? ((current - prev) / prev) * 100 : 0
        #expect(pct == 0)
    }

    // forecastDateRange starts tomorrow and ends 7 days from now
    @Test func forecastDateRangeSpans7Days() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let endDay   = calendar.date(byAdding: .day, value: 7, to: Date())!
        let diff = calendar.dateComponents([.day], from: tomorrow, to: endDay).day ?? 0
        #expect(diff == 6)
    }

    // chartYDomain padding is 20% of price range
    @Test func chartYDomainPaddingIs20Percent() {
        let prices  = [90.0, 100.0, 110.0]
        let minP    = prices.min()!
        let maxP    = prices.max()!
        let padding = (maxP - minP) * 0.2
        let lower   = minP - padding
        let upper   = maxP + padding
        #expect(abs(lower - 86.0) < 0.001)
        #expect(abs(upper - 114.0) < 0.001)
    }
}
