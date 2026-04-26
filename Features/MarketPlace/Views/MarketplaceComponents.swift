
import SwiftUI
import MapKit

// MARK: - Shared Star Rating Badge
struct StarRatingBadge: View {
    let rating: Double
    let count: Int

    var body: some View {
        if count == 0 {
            HStack(spacing: 3) {
                Image(systemName: "star")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("No ratings yet")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        } else {
            HStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
                Text(String(format: "%.1f", rating))
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                Text("(\(count))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

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
        NavigationLink(value: seller) {
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

                    StarRatingBadge(rating: seller.averageRating, count: seller.ratingCount)
                        .padding(.top, 2)

                    HStack {
                        Text("Yield: \(seller.typicalYield) Nuts")
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                        Spacer()
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
        NavigationLink(value: seller) {
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
                    StarRatingBadge(rating: seller.averageRating, count: seller.ratingCount)
                }
                .padding(.leading, 4)
                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
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

// MARK: - Harvest Row Card (same style as SellerRow)
struct HarvestRowCard: View {
    let harvest: HarvestLotItem
    let currentHighestBid: Double
    var sellerRating: Double = 0.0
    var sellerRatingCount: Int = 0

    var body: some View {
        HStack {
            Image("Gemini_Generated_Image_bvc5lzbvc5lzbvc5")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(harvest.propertyName.isEmpty ? harvest.sellerName : harvest.propertyName)
                    .font(.subheadline.bold())
                Text("\(harvest.quantity) Coconuts")
                    .font(.headline)
                Text(harvest.locationName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                StarRatingBadge(rating: sellerRating, count: sellerRatingCount)
            }
            .padding(.leading, 4)
            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
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
}

// MARK: - Harvest Lot Bid Card (horizontal scroll in Discovery)
struct HarvestLotBidCard: View {
    let harvest: HarvestLotItem
    let currentHighestBid: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("Gemini_Generated_Image_bvc5lzbvc5lzbvc5")
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 110)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                if !harvest.propertyName.isEmpty {
                    Text(harvest.propertyName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                Text(harvest.sellerName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(harvest.locationName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(harvest.quantity) Nuts")
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                        Text(harvest.qualityGrade)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Rs \(String(format: "%.0f", currentHighestBid))")
                            .font(.subheadline.bold())
                            .foregroundColor(.blue)
                        Text("Top Bid")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)

                Text("Bid Now")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding(.top, 4)
            }
            .padding(.top, 10)
        }
        .frame(width: 200)
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Temporary Placeholders (To prevent build errors)
//struct BuyerPerformanceView: View {
//    var body: some View { Text("Analytics Dashboard Placeholder").navigationTitle("Performance") }
//}
