// Location: New-Pol-Mure/Features/SellerDashboard/Views/SellerDashboardComponents.swift

import SwiftUI
import MapKit

struct SellerFilterChipsView: View {
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
                        .background(selectedFilter == filter ? Color.orange : Color.gray.opacity(0.1))
                        .foregroundColor(selectedFilter == filter ? .white : .primary)
                        .clipShape(Capsule())
                        .onTapGesture { withAnimation { selectedFilter = filter } }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct MetricCard: View {
    let title: String
    let amount: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(amount)
                    .font(.title2.bold())
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct UrgentActionBanner: View {
    let message: String
    let onVerify: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Action Required")
                    .font(.subheadline.bold())
                Spacer()
            }

            Text(message)
                .font(.subheadline)

            Button(action: onVerify) {
                Text("Verify Quality")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
        )
    }
}

struct RecommendedBuyerCard: View {
    let buyer: RegisteredBuyer
    var lowestOffer: Double?
    var showUrgentBadge: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            Map(interactionModes: []) {
                MapCircle(center: buyer.coordinate, radius: 4000)
                    .foregroundStyle(.orange.opacity(0.3))
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(buyer.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Text(buyer.locationName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Text("Buys: \(buyer.typicalVolume)")
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                        Text(String(format: "%.1f", buyer.rating))
                            .font(.caption.bold())
                    }
                }
                .padding(.top, 4)

                // MARK: - Live Lowest Offer Badge
                if let price = lowestOffer {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.caption2)
                        Text("Lowest: Rs \(String(format: "%.0f", price))")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.green)
                    .padding(.top, 2)
                }
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

struct BuyerRowCard: View {
    let buyer: RegisteredBuyer
    var lowestOffer: Double?
    var showUrgentBadge: Bool = false

    var body: some View {
        NavigationLink(destination: LiveOfferView(buyer: buyer)) {
            HStack {
                Image(systemName: "building.2.crop.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray.opacity(0.5))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(buyer.name)
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                    }
                    Text("Needs \(buyer.typicalVolume)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // MARK: - Live Lowest Offer Badge
                    if let price = lowestOffer {
                        HStack(spacing: 3) {
                            Image(systemName: "tag.fill")
                                .font(.caption2)
                            Text("Rs \(String(format: "%.0f", price))")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.green)
                    }
                }
                .padding(.leading, 4)

                Spacer()

                Text("Pitch Offer")
                    .font(.caption.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct UrgentPostCard: View {
    let post: UrgentRequest
    let buyer: RegisteredBuyer

    var urgencyColor: Color {
        let hoursLeft = post.deadline.timeIntervalSinceNow / 3600
        return hoursLeft < 6 ? .red : .orange
    }

    var body: some View {
        NavigationLink(destination: LiveOfferView(buyer: buyer, isUrgentPitch: true)) {
            HStack(spacing: 12) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(urgencyColor)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(post.buyerName)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Text("\(post.quantity) Nuts · \(post.grade)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption2)
                        Text(post.location)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(post.deadline, style: .relative)
                        .font(.caption.bold())
                        .foregroundColor(urgencyColor)
                    Text("Pitch Offer")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(urgencyColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(urgencyColor.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Temporary Placeholders
//struct SellerPerformanceView: View {
//    var body: some View { Text("Seller Analytics Placeholder").navigationTitle("Performance") }
//}

//struct LiveOfferView: View {
//    let buyer: RegisteredBuyer
//    var body: some View { Text("Pitch Offer to \(buyer.name)").navigationTitle("Pitch Offer") }
//}

