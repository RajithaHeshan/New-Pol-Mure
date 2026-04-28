import Foundation
import CoreML
import CoreLocation

// Wraps the trained CoreML tabular regressor and exposes clean scoring methods
// for both buyer→seller and seller→buyer matching.
final class RecommendationEngine {

    static let shared = RecommendationEngine()

    private let model: MyTabularRegressor_for_cocount_recommendation_feature_1?

    private init() {
        model = try? MyTabularRegressor_for_cocount_recommendation_feature_1(configuration: MLModelConfiguration())
    }

    // MARK: - Buyer → Seller Score
    // Returns a MatchScore (0–100) representing how well a seller fits this buyer.
    // buyerVolume / sellerVolume: parsed from typicalVolume / typicalYield strings (in nuts)
    // distanceKM: straight-line distance between buyer and seller coordinates
    // buyerNeedsExport: 1 if buyer requires export grade, 0 otherwise
    // sellerHasExport: 1 if seller's certificationLevel is "Export", 0 otherwise
    // priceDelta: difference between seller's current highest bid and the market average
    // historicalTransactions: number of completed contracts between this buyer–seller pair
    func scoreSellerForBuyer(
        buyerVolume: Int,
        sellerVolume: Int,
        buyerLocation: CLLocationCoordinate2D,
        sellerLocation: CLLocationCoordinate2D,
        buyerNeedsExport: Bool,
        sellerHasExport: Bool,
        priceDelta: Double,
        historicalTransactions: Int
    ) -> Double {
        guard let model else { return fallbackScore(buyerVolume: buyerVolume, sellerVolume: sellerVolume, buyerLocation: buyerLocation, targetLocation: sellerLocation) }

        let distanceKM = distance(from: buyerLocation, to: sellerLocation)
        let volumeCompatibility = volumeRatio(a: buyerVolume, b: sellerVolume)

        let input = MyTabularRegressor_for_cocount_recommendation_feature_1Input(
            BuyerVolume: Int64(buyerVolume),
            SellerVolume: Int64(sellerVolume),
            VolumeCompatibility: volumeCompatibility,
            DistanceKM: distanceKM,
            BuyerNeedsExport: Int64(buyerNeedsExport ? 1 : 0),
            SellerHasExport: Int64(sellerHasExport ? 1 : 0),
            PriceDelta: priceDelta,
            HistoricalTransactionCount: Int64(historicalTransactions)
        )

        let score = (try? model.prediction(input: input))?.MatchScore ?? 0.0
        return max(0, min(100, score))
    }

    // MARK: - Seller → Buyer Score
    // Same model, roles swapped: seller is the "supply" side, buyer is the "demand" side.
    func scoreBuyerForSeller(
        sellerVolume: Int,
        buyerVolume: Int,
        sellerLocation: CLLocationCoordinate2D,
        buyerLocation: CLLocationCoordinate2D,
        sellerHasExport: Bool,
        buyerNeedsExport: Bool,
        priceDelta: Double,
        historicalTransactions: Int
    ) -> Double {
        return scoreSellerForBuyer(
            buyerVolume: buyerVolume,
            sellerVolume: sellerVolume,
            buyerLocation: buyerLocation,
            sellerLocation: sellerLocation,
            buyerNeedsExport: buyerNeedsExport,
            sellerHasExport: sellerHasExport,
            priceDelta: priceDelta,
            historicalTransactions: historicalTransactions
        )
    }

    // MARK: - Helpers

    func distance(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let locA = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let locB = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return locA.distance(from: locB) / 1000.0
    }

    // Ratio clamped to [0,1]: how well the volumes match (1 = perfect match)
    private func volumeRatio(a: Int, b: Int) -> Double {
        guard a > 0, b > 0 else { return 0 }
        let ratio = Double(min(a, b)) / Double(max(a, b))
        return ratio
    }

    // Simple distance-only fallback when model fails to load
    private func fallbackScore(buyerVolume: Int, sellerVolume: Int, buyerLocation: CLLocationCoordinate2D, targetLocation: CLLocationCoordinate2D) -> Double {
        let km = distance(from: buyerLocation, to: targetLocation)
        return max(0, 100 - km * 0.5)
    }

    // MARK: - Volume Parsing Utility
    // Parses strings like "5000", "5K - 10K Nuts", "5,000" → integer nut count (midpoint for ranges)
    static func parseVolume(_ text: String) -> Int {
        let cleaned = text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "Nuts", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "nuts", with: "")
            .trimmingCharacters(in: .whitespaces)

        // Handle "5K - 10K" style ranges
        let parts = cleaned.components(separatedBy: CharacterSet(charactersIn: "-–"))
            .map { $0.trimmingCharacters(in: .whitespaces) }

        let values = parts.compactMap { part -> Int? in
            let s = part.uppercased().replacingOccurrences(of: " ", with: "")
            if s.hasSuffix("K") {
                return Int((Double(s.dropLast()) ?? 0) * 1000)
            }
            return Int(s)
        }

        switch values.count {
        case 0: return 0
        case 1: return values[0]
        default: return (values.first! + values.last!) / 2
        }
    }
}
