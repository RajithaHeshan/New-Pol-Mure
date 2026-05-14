

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

                List {
                    if viewModel.selectedTab == 0 {
                        if viewModel.isLoadingOffers {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        } else if viewModel.myOffers.isEmpty {
                            SellerEmptyActivityView(message: "You haven't pitched any buyers yet.")
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(viewModel.myOffers) { offer in
                                SellerPendingPitchRow(
                                    buyerName: offer.buyerName.isEmpty ? offer.buyerID : offer.buyerName,
                                    placedAt: offer.placedAt,
                                    currentOffer: offer.amount,
                                    isHighest: viewModel.isHighest(offer: offer),
                                    isUrgent: offer.isUrgentPitch
                                )
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .conditionalSwipeDelete(
                                    enabled: offer.status == "pending" || offer.status == "declined"
                                ) { viewModel.deletePitch(offer) }
                            }
                        }

                    } else if viewModel.selectedTab == 1 {
                        if viewModel.isLoadingBids {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        } else if viewModel.incomingBids.isEmpty {
                            SellerEmptyActivityView(message: "No bids received on your harvests yet.")
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(viewModel.incomingBids) { bid in
                                SellerDirectBidRow(
                                    bid: bid,
                                    onAccept:  { viewModel.acceptBid(bid) },
                                    onDecline: { viewModel.declineBid(bid) }
                                )
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                        }

                    } else if viewModel.selectedTab == 2 {
                        if viewModel.isLoadingTransactions {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        } else if viewModel.transactions.isEmpty {
                            SellerEmptyActivityView(message: "No completed transactions yet.")
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(viewModel.transactions) { tx in
                                SellerTransactionDetailCard(tx: tx)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            if let idx = viewModel.transactions.firstIndex(where: { $0.id == tx.id }) {
                                                viewModel.deleteTransaction(at: IndexSet(integer: idx))
                                            }
                                        } label: {
                                            Label("Hide", systemImage: "eye.slash")
                                        }
                                    }
                            }
                        }

                    } else {
                        if viewModel.isLoadingContracts {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        } else if viewModel.contracts.isEmpty {
                            SellerEmptyActivityView(message: "No active contracts.")
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)


                                
                        } else { //navigate contract view
                            ForEach(viewModel.contracts) { contract in
                                NavigationLink(destination: SellerContractView(contract: contract)) {
                                    SellerContractRow(
                                        contractNumber: contract.contractRef,
                                        partnerName: contract.buyerName,
                                        status: contract.status,
                                        createdAt: contract.createdAt
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .conditionalSwipeDelete(
                                    enabled: contract.status == "completed" || contract.status == "rejected"
                                ) { viewModel.deleteContract(contract) }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color(UIColor.systemGroupedBackground))
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("My Activity")
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
    let placedAt: Date
    let currentOffer: Double
    let isHighest: Bool
    var isUrgent: Bool = false

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: placedAt)
    }

    var body: some View {
        HStack(alignment: .top) {
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
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    Circle()
                        .fill(isHighest ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(isHighest ? "Highest Pitch (Winning)" : "Outpitched")
                        .font(.caption.bold())
                        .foregroundColor(isHighest ? .green : .red)
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
                    if bid.wasAccepted || bid.status == "accepted" {
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

            
            if bid.status == "pending" && !bid.wasAccepted {
                HStack(spacing: 12) {
                    Button(action: onAccept) {
                        Text("Accept Bid")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: onDecline) {
                        Text("Decline")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
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
                    HStack(spacing: 5) {
                        if tx.isUrgent {
                            Image(systemName: "flame.fill")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                        Text("Funds Received")
                            .font(.headline)
                    }
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
                if !tx.harvestName.isEmpty {
                    txRow(icon: "basket.fill", label: "Harvest", value: tx.harvestName)
                }
                if tx.quantity > 0 {
                    txRow(icon: "leaf.fill", label: "Quantity", value: "\(tx.quantity) Coconuts")
                }
                if tx.quantity > 0 && tx.pricePerNut > 0 {
                    txRow(icon: "scalemass.fill", label: "Price / Nut", value: "Rs \(String(format: "%.2f", tx.pricePerNut))")
                }
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
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(tx.isUrgent ? Color.orange.opacity(0.5) : Color.green.opacity(0.2), lineWidth: 1)
        )
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
    let createdAt: Date

    private var statusColor: Color {
        switch status {
        case "completed":                       return .green
        case "escrow":                          return .orange
        case "inspection", "qualityApproved":  return .blue
        case "dispute":                         return .red
        case "rejected":                        return .gray
        default:                                return .orange
        }
    }

    private var statusLabel: String {
        switch status {
        case "escrow":           return "Escrow Held"
        case "inspection":       return "Inspection Pending"
        case "qualityApproved":  return "Quality Approved"
        case "completed":        return "Completed"
        case "rejected":         return "Rejected"
        case "dispute":          return "Disputed"
        default:                 return status.capitalized
        }
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: createdAt)
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(partnerName)
                    .font(.headline)
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(statusLabel)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.12))
                    .foregroundColor(statusColor)
                    .clipShape(Capsule())
                HStack(spacing: 2) {
                    Text("View Logistics")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    SellerActivityDashboardView()
}
