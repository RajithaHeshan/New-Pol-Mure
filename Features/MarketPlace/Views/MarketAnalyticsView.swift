
import SwiftUI
import Charts

struct MarketAnalyticsView: View {
    @State private var viewModel = MarketAnalyticsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

         
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Market Average")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.vertical, 8)
                    } else {
                        Text("Rs \(viewModel.currentMarketAverage, specifier: "%.2f")")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text(viewModel.weeklyChangeLabel)
                            .font(.caption.bold())
                            .foregroundColor(viewModel.weeklyChangeIsPositive ? .green : .red)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // MARK: - 7-Day Price Trend Chart
                VStack(alignment: .leading) {
                    Text("7-Day Price Trend (Kurunegala Zone)")
                        .font(.headline)
                        .padding(.bottom, 10)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                    } else {
                        Chart {
                            ForEach(viewModel.priceHistory) { item in
                                LineMark(
                                    x: .value("Day", item.day),
                                    y: .value("Price", item.price)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Color.blue.gradient)
                                .lineStyle(StrokeStyle(lineWidth: 3))

                                AreaMark(
                                    x: .value("Day", item.day),
                                    y: .value("Price", item.price)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.0)]), startPoint: .top, endPoint: .bottom))
                            }
                        }
                        .frame(height: 250)
                        .chartYScale(domain: viewModel.chartYDomain)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal)

                // MARK: - Market Insight
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.max.fill").foregroundColor(.orange)
                        Text("Market Insight").font(.headline)
                    }
                    Text(viewModel.marketInsight)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Market Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MarketAnalyticsView()
    }
}
