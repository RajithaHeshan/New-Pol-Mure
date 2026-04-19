
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


struct RecommendedSellerCard: View {
    let seller: SellerLocation
    let currentHighestBid: Double

    var body: some View {
        NavigationLink(destination: LiveBiddingView(lot: seller.toHarvestLot(currentBid: currentHighestBid))) {
            VStack(alignment: .leading) {
                Map(interactionModes: []) {
                    MapCircle(center: seller.coordinate, radius: 4000)
                        .foregroundStyle(.blue.opacity(0.3))
                    Annotation(seller.sellerName, coordinate: seller.coordinate) {
                        Image(systemName: "leaf.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.green)
                            .clipShape(Circle())
                    }
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(seller.sellerName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(seller.locationName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Yield: \(seller.typicalYield) Nuts")
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                        Spacer()
                        // MARK: - Current Highest Bid Badge
                        Text("Rs \(String(format: "%.0f", currentHighestBid))")
                            .font(.caption.bold())
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
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
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Seller Row (Vertical List)
struct SellerRow: View {
    let seller: SellerLocation
    let currentHighestBid: Double

    var body: some View {
        NavigationLink(destination: LiveBiddingView(lot: seller.toHarvestLot(currentBid: currentHighestBid))) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray.opacity(0.5))

                VStack(alignment: .leading, spacing: 4) {
                    Text(seller.sellerName)
                        .font(.subheadline.bold())
                    Text("\(seller.typicalYield) Coconuts")
                        .font(.headline)
                    Text(seller.locationName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 4)
                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    // MARK: - Current Highest Bid
                    Text("Highest Bid")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Rs \(String(format: "%.0f", currentHighestBid))")
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)

                    Text("Bid Now")
                        .font(.caption.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Temporary Placeholders (To prevent build errors)
struct BuyerPerformanceView: View {
    var body: some View { Text("Analytics Dashboard Placeholder").navigationTitle("Performance") }
}
