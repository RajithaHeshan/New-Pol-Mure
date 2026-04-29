import SwiftUI
import Charts

struct SellerPerformanceView: View {
    @State private var viewModel = SellerPerformanceViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - Timeframe Picker
                Picker("Timeframe", selection: $viewModel.selectedTimeframe) {
                    ForEach(viewModel.timeframes, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: viewModel.selectedTimeframe) { _, _ in
                    viewModel.onTimeframeChanged()
                }

                // MARK: - Period Label
                Text(periodDescription(for: viewModel.selectedTimeframe))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)

                // MARK: - KPI Cards
                VStack(spacing: 16) {
                    HStack {
                        SellerKPICard(
                            title: "Nuts Sold",
                            value: viewModel.nutsSold > 0 ? "\(viewModel.nutsSold)" : "—",
                            subtitle: "Total Volume",
                            icon: "shippingbox.fill",
                            color: .green
                        )
                        SellerKPICard(
                            title: "Pitch Success",
                            value: viewModel.pitchSuccessRate > 0 ? "\(viewModel.pitchSuccessRate)%" : "—",
                            subtitle: "Offers Accepted",
                            icon: "hand.raised.fill",
                            color: .orange
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gross Revenue (\(viewModel.selectedTimeframe))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if viewModel.isLoading {
                            ProgressView().padding(.vertical, 8)
                        } else {
                            Text(viewModel.totalRevenue > 0 ? "Rs \(viewModel.totalRevenue, specifier: "%.0f")" : "Rs 0")
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .foregroundColor(viewModel.totalRevenue > 0 ? .primary : .secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                .padding(.horizontal)

                // MARK: - Revenue Chart
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Detailed Revenue")
                            .font(.title3.bold())
                        Spacer()
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Circle().fill(Color.green).frame(width: 8, height: 8)
                                Text("Auctions").font(.caption).foregroundColor(.secondary)
                            }
                            HStack(spacing: 4) {
                                Circle().fill(Color.green.opacity(0.4)).frame(width: 8, height: 8)
                                Text("Pitches").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity).frame(height: 250)
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .padding(.horizontal)
                    } else if viewModel.hasNoRevenueData {
                        VStack(spacing: 8) {
                            Image(systemName: "chart.bar")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No revenue data for this period.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity).frame(height: 250)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    } else {
                        Chart(viewModel.detailedRevenueData) { data in
                            BarMark(
                                x: .value("Period", data.period),
                                y: .value("Amount (Rs)", data.amount)
                            )
                            .foregroundStyle(by: .value("Revenue Source", data.source))
                            .cornerRadius(6)
                        }
                        .chartForegroundStyleScale([
                            "Auction Sales":    Color.green,
                            "Accepted Pitches": Color.green.opacity(0.4)
                        ])
                        .frame(height: 250)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }

                // MARK: - Seller Insights
                VStack(alignment: .leading, spacing: 16) {
                    Text("Seller Insights")
                        .font(.title3.bold())
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        SellerInsightRow(icon: "arrow.up.right.circle.fill", color: .green,  title: "Premium Pricing",  desc: viewModel.insightPremiumDesc)
                        SellerInsightRow(icon: "chart.pie.fill",              color: .blue,   title: "Pitch Dependency", desc: viewModel.insightPitchDesc)
                        SellerInsightRow(icon: "clock.fill",                  color: .orange, title: "Escrow Turnaround", desc: viewModel.insightEscrowDesc)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("My Performance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func periodDescription(for timeframe: String) -> String {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"

        switch timeframe {
        case "Week":
            let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
            return "\(formatter.string(from: start)) – \(formatter.string(from: now))"
        case "Year":
            let start = calendar.date(byAdding: .month, value: -11,
                to: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!) ?? now
            return "\(formatter.string(from: start)) – \(formatter.string(from: now))"
        default:
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMMM yyyy"
            return monthFormatter.string(from: now)
        }
    }
}

struct SellerKPICard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .padding(8)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                Spacer()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.caption).foregroundColor(.secondary)
                Text(value).font(.title2.bold())
                Text(subtitle).font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct SellerInsightRow: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.bold())
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack { SellerPerformanceView() }
}
