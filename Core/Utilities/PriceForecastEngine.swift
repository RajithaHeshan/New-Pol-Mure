import CoreML

// Zone ID encoding — must match the CSV training data
private let zoneEncoding: [String: Int64] = [
    "anuradhapura": 0,
    "colombo":      1,
    "galle":        2,
    "gampaha":      3,
    "kandy":        4,
    "kegalle":      5,
    "kurunegala":   6,
    "matale":       7,
    "puttalam":     8,
    "ratnapura":    9,
]

struct PriceForecast {
    let predictedPrice: Double   // Rs per nut, 7 days from now
    let zoneName: String
}

final class PriceForecastEngine {

    static let shared = PriceForecastEngine()

    private let model: CoconutPriceForecaster_1?

    private init() {
        model = try? CoconutPriceForecaster_1(configuration: MLModelConfiguration())
    }

    // MARK: - Predict 7-day price for a given zone using live market data
    // All inputs come directly from MarketAnalyticsViewModel — no new queries needed.
    func predict(
        zoneID: String,
        weeklyAvgPrice: Double,
        prevWeekAvgPrice: Double,
        weeklyChangePct: Double,
        weeklyTransactionCount: Int
    ) -> PriceForecast? {
        guard let model else { return nil }
        guard weeklyAvgPrice > 0 else { return nil }  // no data yet for this zone

        let calendar   = Calendar.current
        let now        = Date()
        let month      = Int64(calendar.component(.month,   from: now))
        // Convert Apple weekday (1=Sun...7=Sat) to 0=Mon...6=Sun
        let appleWeekday = calendar.component(.weekday, from: now)
        let dayOfWeek    = Int64((appleWeekday + 5) % 7)

        let encodedZone  = zoneEncoding[zoneID] ?? 0
        let prevAvg      = prevWeekAvgPrice > 0 ? prevWeekAvgPrice : weeklyAvgPrice
        let txCount      = Int64(max(1, weeklyTransactionCount))

        let input = CoconutPriceForecaster_1Input(
            zone_id:                  encodedZone,
            month:                    month,
            day_of_week:              dayOfWeek,
            weekly_avg_price:         weeklyAvgPrice,
            prev_week_avg_price:      prevAvg,
            weekly_change_pct:        weeklyChangePct,
            weekly_transaction_count: txCount
        )

        guard let output = try? model.prediction(input: input) else { return nil }

        let predicted = max(50.0, min(200.0, output.predicted_price_7d))

        return PriceForecast(
            predictedPrice: predicted,
            zoneName: zoneID
        )
    }
}
