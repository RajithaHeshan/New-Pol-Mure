

import SwiftUI
import Charts

struct BuyerPerformanceView: View {
    @State private var viewModel = BuyerPerformanceViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // 1. Timeframe Selector
                Picker("Timeframe", selection: $viewModel.selectedTimeframe) {
                    ForEach(viewModel.timeframes, id: \.self) { frame in
                        Text(frame).tag(frame)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: viewModel.selectedTimeframe) { _, _ in
                    viewModel.onTimeframeChanged()
                }

                // 2. High-Level KPI Summary
                VStack(spacing: 16) {
                    HStack {
                        BuyerKPICard(
                            title: "Total Volume",
                            value: viewModel.totalVolumeNuts > 0 ? "\(viewModel.totalVolumeNuts)" : "—",
                            subtitle: "Nuts Acquired",
                            icon: "shippingbox.fill",
                            color: .blue
                        )
                        BuyerKPICard(
                            title: "Win Rate",
                            value: "\(viewModel.winRate)%",
                            subtitle: "Bids Won",
                            icon: "trophy.fill",
                            color: .green
                        )
                    }

                    // Large Spend Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Spend (\(viewModel.selectedTimeframe))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.vertical, 8)
                        } else {
                            Text("Rs \(viewModel.totalSpend, specifier: "%.0f")")
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                .padding(.horizontal)

               
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Detailed Expenditure")
                            .font(.title3.bold())
                        Spacer()
                       
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Circle().fill(Color.blue).frame(width: 8, height: 8)
                                Text("Bids").font(.caption).foregroundColor(.secondary)
                            }
                            HStack(spacing: 4) {
                                Circle().fill(Color.blue.opacity(0.5)).frame(width: 8, height: 8)
                                Text("Offers").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .padding(.horizontal)
                    } else if viewModel.detailedSpendData.isEmpty {
                        Text("No spend data for this period.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .padding(.horizontal)
                    } else {
                        Chart(viewModel.detailedSpendData) { data in
                            BarMark(
                                x: .value("Period", data.period),
                                y: .value("Amount (Rs)", data.amount)
                            )
                            .foregroundStyle(by: .value("Spend Source", data.source))
                            .cornerRadius(6)
                        }
                        .chartForegroundStyleScale([
                            "Bids Won":        Color.blue,
                            "Accepted Offers": Color.blue.opacity(0.5)
                        ])
                        .frame(height: 250)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }

                // 4. Personal Insights
                VStack(alignment: .leading, spacing: 16) {
                    Text("Personal Insights")
                        .font(.title3.bold())
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        BuyerInsightRow(icon: "arrow.down.right.circle.fill", color: .green,  title: "Great Sourcing",   desc: viewModel.insightSourcingDesc)
                        BuyerInsightRow(icon: "exclamationmark.triangle.fill", color: .orange, title: "Bid Success",      desc: viewModel.insightBidSuccessDesc)
                        BuyerInsightRow(icon: "lightbulb.fill",                color: .yellow, title: "Offer Reliance",   desc: viewModel.insightOfferRelianceDesc)
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
}

// MARK: - Reusable Analytics Subviews

struct BuyerKPICard: View {
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
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2.bold())
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct BuyerInsightRow: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
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
    NavigationStack {
        BuyerPerformanceView()
    }
}
