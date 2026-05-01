

import SwiftUI

struct SellerActivityDashboardView: View {
    @State private var viewModel = SellerActivityDashboardViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                
                Picker("Activity Type", selection: $viewModel.selectedTab) {
                    Text("Active Pitches").tag(0)
                    Text("Direct Bids").tag(1)
                    Text("Transactions").tag(2)
                    Text("Contracts").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color(UIColor.systemBackground))

                ScrollView {
                    VStack(spacing: 16) {

                        if viewModel.selectedTab == 0 {
                          
                            if viewModel.isLoadingOffers {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            } else if viewModel.myOffers.isEmpty {
                                SellerEmptyActivityView(message: "You haven't pitched any buyers yet.")
                            } else {
                                ForEach(viewModel.myOffers) { offer in
                                    SellerPendingPitchRow(
                                        buyerName: offer.buyerName.isEmpty ? offer.buyerID : offer.buyerName,
                                        location: "",
                                        currentOffer: offer.amount,
                                        isLowest: viewModel.isLowest(offer: offer),
                                        isUrgent: offer.isUrgentPitch
                                    )
                                }
                            }

                        } else if viewModel.selectedTab == 1 {
                            // DIRECT BIDS
                            HStack {
                                Text("Inbound bids on your active harvests")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)

                            if viewModel.isLoadingBids {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            } else if viewModel.incomingBids.isEmpty {
                                SellerEmptyActivityView(message: "No bids received on your harvests yet.")
                            } else {
                                ForEach(viewModel.incomingBids) { bid in
                                    SellerDirectBidRow(
                                        bid: bid,
                                        onAccept:  { viewModel.acceptBid(bid) },
                                        onDecline: { viewModel.declineBid(bid) }
                                    )
                                }
                            }

                        } else if viewModel.selectedTab == 2 {
                           
                            HStack {
                                Text("Recent Financial Transactions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)

                            if viewModel.isLoadingTransactions {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            } else if viewModel.transactions.isEmpty {
                                SellerEmptyActivityView(message: "No completed transactions yet.")
                            } else {
                                ForEach(viewModel.transactions) { tx in
                                    SellerTransactionDetailCard(tx: tx)
                                }
                            }

                        } else {
                         
                            if viewModel.isLoadingContracts {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            } else if viewModel.contracts.isEmpty {
                                SellerEmptyActivityView(message: "No active contracts.")
                            } else {
                                ForEach(viewModel.contracts) { contract in
                                    NavigationLink(destination: SellerContractView(contract: contract)) {
                                        SellerContractRow(
                                            contractNumber: contract.contractRef,
                                            partnerName: contract.buyerName,
                                            status: viewModel.statusDisplayText(contract.status)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationTitle("My Activity")
            // Apply Orange Tint to the Segmented Picker
            .tint(.orange)
        }
    }
}



struct SellerEmptyActivityView: View {
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}



struct SellerPendingPitchRow: View {
    let buyerName: String
    let location: String
    let currentOffer: Double
    let isLowest: Bool
    var isUrgent: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if isUrgent {
                        Image(systemName: "flame.fill")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    Text(buyerName)
                        .font(.headline)
                }
                if !location.isEmpty {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                HStack {
                    Circle()
                        .fill(isLowest ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(isLowest ? "Lowest Pitch (Winning)" : "Underbid")
                        .font(.caption.bold())
                        .foregroundColor(isLowest ? .green : .red)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("My Pitch")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Rs \(currentOffer, specifier: "%.2f")")
                    .font(.title3.bold())
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            isUrgent ? RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.4), lineWidth: 1) : nil
        )
        .padding(.horizontal)
    }
}

struct SellerDirectBidRow: View {
    let bid: Bid
    let onAccept:  () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                Image(systemName: "building.2.crop.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.orange.opacity(0.5)) // Orange Theme

                VStack(alignment: .leading, spacing: 4) {
                    Text(bid.bidderName)
                        .font(.headline)
                    Text(bid.placedAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Rs \(bid.amount, specifier: "%.2f") / nut")
                        .font(.subheadline)
                        .foregroundColor(.green)

                    // Status badge — shown after seller acts
                    if bid.status == "accepted" {
                        Text("Accepted")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    } else if bid.status == "declined" {
                        Text("Declined")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .clipShape(Capsule())
                    }
                }
            }

            
            if bid.status == "pending" {
                HStack(spacing: 12) {
                    Button(action: onDecline) {
                        Text("Decline")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }

                    Button(action: onAccept) {
                        Text("Accept Bid")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.orange) // Orange Theme
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}


struct SellerTransactionDetailCard: View {
    let tx: Transaction

    private var dateTimeString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: tx.completedAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
           
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Funds Received")
                        .font(.headline)
                    Text("Contract \(tx.contractRef)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("+ Rs \(tx.amount, specifier: "%.0f")")
                        .font(.title3.bold())
                        .foregroundColor(.green)
                    Text("Net Rs \(tx.netAmount, specifier: "%.0f")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            Divider().padding(.horizontal)

            VStack(spacing: 10) {
                txRow(icon: "building.2.fill", label: "Buyer", value: tx.buyerName)
                txRow(icon: "leaf.fill", label: "Quantity", value: "\(tx.quantity) Coconuts")
                txRow(icon: "scalemass.fill", label: "Price / Nut", value: "Rs \(String(format: "%.2f", tx.pricePerNut))")
                txRow(icon: "percent", label: "Platform Fee (2%)", value: "Rs \(String(format: "%.2f", tx.transactionFee))")
                if !tx.locationName.isEmpty {
                    txRow(icon: "mappin.and.ellipse", label: "Location", value: tx.locationName)
                }
                txRow(icon: "calendar", label: "Completed", value: dateTimeString)
            }
            .padding()
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.green.opacity(0.2), lineWidth: 1))
        .padding(.horizontal)
    }

    private func txRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct SellerContractRow: View {
    let contractNumber: String
    let partnerName: String
    let status: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Contract \(contractNumber)")
                    .font(.headline)
                Text(partnerName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(status)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())

                HStack {
                    Text("View Logistics")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    SellerActivityDashboardView()
}
