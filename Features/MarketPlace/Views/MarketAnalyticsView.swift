import SwiftUI
import Charts

struct MarketAnalyticsView: View {
    @State private var viewModel: MarketAnalyticsViewModel

    init(preselectedZone: CoconutZone? = nil) {
        _viewModel = State(initialValue: MarketAnalyticsViewModel(preselectedZone: preselectedZone))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

               
                zonePicker

            
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Market Average")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if viewModel.isLoading {
                        ProgressView().padding(.vertical, 8)
                    } else if viewModel.currentMarketAverage == 0 {
                        Text("No data")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                        Text("No bids placed in this zone yet.")
                            .font(.caption)
                            .foregroundColor(.secondary)
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

              
                VStack(alignment: .leading) {
                    Text("7-Day Price Trend (\(viewModel.selectedZone.displayName))")
                        .font(.headline)

                    // Dynamic date range — updates every time zone or data changes
                    if !viewModel.chartDateRange.isEmpty {
                        Text(viewModel.chartDateRange)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer().frame(height: 10)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                    } else if viewModel.hasNoData {
                        VStack(spacing: 8) {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No bid data for \(viewModel.selectedZone.displayName) yet.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                    } else {
                        Chart {
                            ForEach(viewModel.priceHistory) { item in
                                LineMark(
                                    x: .value("Date", item.id),   // "24 Apr" — actual date on x-axis
                                    y: .value("Price", item.price)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Color.blue.gradient)
                                .lineStyle(StrokeStyle(lineWidth: 3))

                                AreaMark(
                                    x: .value("Date", item.id),
                                    y: .value("Price", item.price)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.0)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
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

               
                if viewModel.selectedZone.id != "all" {
                    HStack(spacing: 8) {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(.blue)
                        Text("Showing bids within \(Int(viewModel.selectedZone.radiusKM)) km of \(viewModel.selectedZone.displayName) centre.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
            }
            .padding(.bottom, 30)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Market Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }

        private var zonePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.zones) { zone in
                    let isSelected = viewModel.selectedZone.id == zone.id
                    Button(action: {
                        viewModel.selectedZone = zone
                        viewModel.recomputeTrend()
                    }) {
                        Text(zone.displayName)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(isSelected ? Color.blue : Color(UIColor.secondarySystemGroupedBackground))
                            .foregroundColor(isSelected ? .white : .blue)
                            .overlay(
                                Capsule()
                                    .strokeBorder(isSelected ? Color.clear : Color.blue.opacity(0.4), lineWidth: 1.5)
                            )
                            .clipShape(Capsule())
                            .shadow(color: isSelected ? Color.blue.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

#Preview {
    NavigationStack {
        MarketAnalyticsView()
    }
}
