import Foundation
import CoreML
import CoreLocation


final class RecommendationEngine {

    static let shared = RecommendationEngine()

    private let model: NewMyTabularRegressor_1?

    private init() {
        model = try? NewMyTabularRegressor_1(configuration: MLModelConfiguration())
    }

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

        let input = NewMyTabularRegressor_1Input(
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
