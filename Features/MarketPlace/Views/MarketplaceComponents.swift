// Location: New-Pol-Mure/Features/Marketplace/Views/MarketplaceComponents.swift

import SwiftUI
import MapKit

struct FilterChipsView: View {
    let filters: [String]
    @Binding var selectedFilter: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(filters, id: \.self) { filter in
                    Text(filter)
                        .font(selectedFilter == filter ? .subheadline.bold() : .subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedFilter == filter ? Color.blue : Color.gray.opacity(0.1))
                        .foregroundColor(selectedFilter == filter ? .white : .primary)
                        .clipShape(Capsule())
                        .onTapGesture { withAnimation { selectedFilter = filter } }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct RecommendedLotCard: View {
    let lot: HarvestLot
    var body: some View {
        VStack(alignment: .leading) {
            Map(interactionModes: []) {
                MapCircle(center: lot.coordinate, radius: 4000)
                    .foregroundStyle(.blue.opacity(0.3))
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(lot.quantity) Nuts")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(lot.locationName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Top Bid: Rs \(lot.currentBid, specifier: "%.2f")")
                        .font(.subheadline.bold())
                        .foregroundColor(.green)
                    Spacer()
                    Image(systemName: "timer")
                        .foregroundColor(.red)
                }
                .padding(.top, 4)
            }
            .padding(.top, 8)
        }
        .frame(width: 240)
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct GeneralAuctionRow: View {
    let lot: HarvestLot
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(lot.sellerInitial)
                    .font(.subheadline.bold())
                Text("\(lot.quantity) Coconuts")
                    .font(.headline)
                Text(lot.locationName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 4)
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text("Rs \(lot.currentBid, specifier: "%.2f")")
                    .font(.title3.bold())
                    .foregroundColor(.green)
                
                NavigationLink(destination: LiveBiddingView(lot: lot)) {
                    Text("View Bid")
                        .font(.caption.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Temporary Placeholders (To prevent build errors)
struct BuyerPerformanceView: View {
    var body: some View { Text("Analytics Dashboard Placeholder").navigationTitle("Performance") }
}

struct LiveBiddingView: View {
    let lot: HarvestLot
    var body: some View { Text("Bidding View for \(lot.quantity) nuts").navigationTitle("Live Bid") }
}

