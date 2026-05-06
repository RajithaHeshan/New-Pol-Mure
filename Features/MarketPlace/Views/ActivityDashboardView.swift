

import SwiftUI

struct ActivityDashboardView: View {
    @State private var viewModel = ActivityDashboardViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                Picker("Activity Type", selection: $viewModel.selectedTab) {
                    Text("Bids").tag(0)
                    Text("Offers").tag(1)
                    Text("Transactions").tag(2)
                    Text("Contracts").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color(UIColor.systemBackground))

                List {
                    if viewModel.selectedTab == 0 {
                        if viewModel.isLoadingBids {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        } else if viewModel.myBids.isEmpty {
                            EmptyActivityView(message: "You haven't placed any bids yet.")
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(viewModel.myBids) { bid in
                                PendingBidRow(
                                    sellerName: bid.sellerName.isEmpty ? "Seller" : bid.sellerName,
                                    placedAt: bid.placedAt,
                                    currentBid: bid.amount,
                                    isWinning: viewModel.isWinning(bid: bid)
                                )
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .conditionalSwipeDelete(
                                    enabled: bid.status == "pending"
                                ) { viewModel.deleteBid(bid) }
                            }
                        }

                    } else if viewModel.selectedTab == 1 {
                        if viewModel.isLoadingOffers {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        } else if viewModel.incomingOffers.isEmpty {
                            EmptyActivityView(message: "No seller pitches received yet.")
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(viewModel.incomingOffers) { offer in
                                DirectOfferRow(
                                    offer: offer,
                                    isUrgent: offer.isUrgentPitch,
                                    onAccept:  { viewModel.acceptOffer(offer) },
                                    onDecline: { viewModel.declineOffer(offer) }
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
                            EmptyActivityView(message: "No completed transactions yet.")
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(viewModel.transactions) { tx in
                                TransactionDetailCard(tx: tx)
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
                            EmptyActivityView(message: "No active contracts.")
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(viewModel.contracts) { contract in
                                NavigationLink(destination: ActiveContractView(contract: contract)) {
                                    ContractRow(
                                        contractNumber: contract.contractRef,
                                        partnerName: contract.sellerName,
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
        }
    }
}




struct EmptyActivityView: View {
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


struct PendingBidRow: View {
    let sellerName: String
    let placedAt: Date
    let currentBid: Double
    let isWinning: Bool

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: placedAt)
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(sellerName)
                    .font(.headline)
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    Circle()
                        .fill(isWinning ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(isWinning ? "Highest Bidder" : "Outbid")
                        .font(.caption.bold())
                        .foregroundColor(isWinning ? .green : .red)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("My Bid")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Rs \(currentBid, specifier: "%.2f")")
                    .font(.title3.bold())
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct DirectOfferRow: View {
    let offer:     Offer
    var isUrgent:  Bool = false
    let onAccept:  () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray.opacity(0.5))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if isUrgent {
                            Image(systemName: "flame.fill")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        Text(offer.sellerName)
                            .font(.headline)
                    }
                    Text(offer.placedAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Rs \(offer.amount, specifier: "%.2f") / nut")
                        .font(.subheadline)
                        .foregroundColor(.green)

                    // Status badge — shown after buyer acts
                    if offer.status == "accepted" {
                        Text("Accepted")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.12))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    } else if offer.status == "declined" {
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

            
            if offer.status == "pending" {
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
                        Text("Accept Pitch")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
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

struct TransactionDetailCard: View {
    let tx: Transaction

    private var dateTimeString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: tx.completedAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header strip
            HStack {
                Image(systemName: tx.isCredit ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(tx.isCredit ? .green : .blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tx.isCredit ? "Payment Received" : "Payment Made")
                        .font(.headline)
                    Text("Contract \(tx.contractRef)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(tx.isCredit ? "+" : "-") Rs \(tx.amount, specifier: "%.0f")")
                        .font(.title3.bold())
                        .foregroundColor(tx.isCredit ? .green : .blue)
                    Text("Net Rs \(tx.netAmount, specifier: "%.0f")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            Divider().padding(.horizontal)

            // Detail rows
            VStack(spacing: 10) {
                txRow(icon: "person.fill", label: "Seller", value: tx.sellerName)
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

struct ContractRow: View {
    let contractNumber: String
    let partnerName: String
    let status: String
    let createdAt: Date

    private var statusColor: Color {
        switch status {
        case "completed":                        return .green
        case "escrow":                           return .blue
        case "inspection", "qualityApproved":   return .orange
        case "dispute":                          return .red
        case "rejected":                         return .gray
        default:                                 return .blue
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
                        .foregroundColor(.blue)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    ActivityDashboardView()
}
