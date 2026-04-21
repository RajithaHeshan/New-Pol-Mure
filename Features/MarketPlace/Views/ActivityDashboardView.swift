

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

                ScrollView {
                    VStack(spacing: 16) {

                        if viewModel.selectedTab == 0 {

                            if viewModel.isLoadingBids {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            } else if viewModel.myBids.isEmpty {
                                EmptyActivityView(message: "You haven't placed any bids yet.")
                            } else {
                                ForEach(viewModel.myBids) { bid in
                                    PendingBidRow(
                                        estateName: bid.sellerID,
                                        currentBid: bid.amount,
                                        isWinning: viewModel.isWinning(bid: bid)
                                    )
                                }
                            }

                        } else if viewModel.selectedTab == 1 {

                            // MARK: - Tab 1: Incoming Offers from Sellers
                            HStack {
                                Text("Direct pitches from Sellers")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)

                            if viewModel.isLoadingOffers {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            } else if viewModel.incomingOffers.isEmpty {
                                EmptyActivityView(message: "No seller pitches received yet.")
                            } else {
                                ForEach(viewModel.incomingOffers) { offer in
                                    DirectOfferRow(
                                        sellerName: offer.sellerName,
                                        location: "",
                                        quantity: 0,
                                        price: offer.amount
                                    )
                                }
                            }

                        } else if viewModel.selectedTab == 2 {

                            // MARK: - Tab 2: Financial Transactions
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
                                EmptyActivityView(message: "No transactions found.")
                            } else {
                                ForEach(viewModel.transactions) { tx in
                                    TransactionRow(
                                        date: viewModel.formattedDate(tx.date),
                                        description: tx.description,
                                        amount: tx.amount,
                                        isCredit: tx.isCredit
                                    )
                                }
                            }

                        } else {

                            // MARK: - Tab 3: Contracts
                            if viewModel.isLoadingContracts {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            } else if viewModel.contracts.isEmpty {
                                EmptyActivityView(message: "No active contracts.")
                            } else {
                                ForEach(viewModel.contracts) { contract in
                                    NavigationLink(destination: Text("Active Contract View Placeholder")) {
                                        ContractRow(
                                            contractNumber: contract.contractRef,
                                            sellerName: contract.sellerName,
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
        }
    }
}


// MARK: - Empty State

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
    let estateName: String
    let currentBid: Double
    let isWinning: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(estateName)
                    .font(.headline)
                HStack {
                    Circle()
                        .fill(isWinning ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(isWinning ? "Highest Bidder" : "Outbid")
                        .font(.caption.bold())
                        .foregroundColor(isWinning ? .green : .red)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
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
        .padding(.horizontal)
    }
}

struct DirectOfferRow: View {
    let sellerName: String
    let location: String
    let quantity: Int
    let price: Double

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray.opacity(0.5))

                VStack(alignment: .leading, spacing: 4) {
                    Text(sellerName)
                        .font(.headline)
                    if !location.isEmpty {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.caption)
                            Text(location)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if quantity > 0 {
                        Text("\(quantity) Nuts")
                            .font(.headline.bold())
                    }
                    Text("Rs \(price, specifier: "%.2f") / nut")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }

            // ACTION BUTTONS
            HStack(spacing: 12) {
                Button(action: { /* Reject Logic */ }) {
                    Text("Decline")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }

                Button(action: { /* Accept -> Moves to Contracts and locks Escrow */ }) {
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
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct TransactionRow: View {
    let date: String
    let description: String
    let amount: Double
    let isCredit: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(description)
                    .font(.headline)
                Text(date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(isCredit ? "+" : "-") Rs \(amount, specifier: "%.2f")")
                .font(.title3.bold())
                .foregroundColor(isCredit ? .green : .primary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ContractRow: View {
    let contractNumber: String
    let sellerName: String
    let status: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Contract \(contractNumber)")
                    .font(.headline)
                Text(sellerName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(status)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())

                HStack {
                    Text("View Logistics")
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.blue)
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
    ActivityDashboardView()
}
