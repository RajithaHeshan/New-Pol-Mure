import SwiftUI
import Charts

struct SellerPerformanceView: View {
    @State private var viewModel = SellerPerformanceViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

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
                            value: "\(viewModel.pitchSuccessRate)%",
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
                            ProgressView()
                                .padding(.vertical, 8)
                        } else {
                            Text("Rs \(viewModel.totalRevenue, specifier: "%.0f")")
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
                        Text("Detailed Revenue")
                            .font(.title3.bold())
                        Spacer()
                       
                        HStack(spacing: 8) {
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
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .padding(.horizontal)
                    } else if viewModel.detailedRevenueData.isEmpty {
                        Text("No revenue data for this period.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
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

            
                VStack(alignment: .leading, spacing: 16) {
                    Text("Seller Insights")
                        .font(.title3.bold())
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        SellerInsightRow(icon: "arrow.up.right.circle.fill", color: .green,  title: "Premium Pricing",  desc: viewModel.insightPremiumDesc)
                        SellerInsightRow(icon: "chart.pie.fill",              color: .blue,   title: "Pitch Dependency", desc: viewModel.insightPitchDesc)
                        SellerInsightRow(icon: "clock.fill",                  color: .orange, title: "Escrow Delays",    desc: viewModel.insightEscrowDesc)
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

struct SellerInsightRow: View {
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
        SellerPerformanceView()
    }
}
