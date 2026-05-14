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
    var isDispute: Bool = false
    var disputeReason: String? = nil
    var disputeNotes: String? = nil
    var disputeCounterOffer: Double? = nil
    let onVerify: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isDispute ? "exclamationmark.shield.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(isDispute ? .red : .orange)
                Text(isDispute ? "Dispute Raised" : "Action Required")
                    .font(.subheadline.bold())
                    .foregroundColor(isDispute ? .red : .primary)
                Spacer()
            }

            Text(message)
                .font(.subheadline)

            if isDispute, let reason = disputeReason {
                VStack(alignment: .leading, spacing: 6) {
                    DisputeDetailRow(label: "Reason", value: reason)
                    if let notes = disputeNotes {
                        DisputeDetailRow(label: "Notes", value: notes)
                    }
                    if let counter = disputeCounterOffer {
                        DisputeDetailRow(label: "Counter-Offer", value: "Rs \(Int(counter))")
                    }
                }
                .padding(10)
                .background(Color.red.opacity(0.06))
                .cornerRadius(10)
            }

            Button(action: onVerify) {
                Text(isDispute ? "Review Dispute" : "Verify Quality")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isDispute ? Color.red : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke((isDispute ? Color.red : Color.orange).opacity(0.5), lineWidth: 1)
        )
    }
}

private struct DisputeDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("\(label):")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct RecommendedBuyerCard: View {
    let buyer: RegisteredBuyer
    var highestOffer: Double?
    var showUrgentBadge: Bool = false
    var isPitchLocked: Bool = false

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
                    StarRatingBadge(rating: buyer.rating, count: buyer.ratingCount)
                }
                .padding(.top, 4)

                // MARK: - Live Highest Offer Badge
                if let price = highestOffer {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.caption2)
                        Text("Highest: Rs \(String(format: "%.0f", price))")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.green)
                    .padding(.top, 2)
                }

                Text(isPitchLocked ? "Pitched" : "Pitch Offer")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(isPitchLocked ? Color.gray.opacity(0.3) : Color.orange)
                    .foregroundColor(isPitchLocked ? .secondary : .white)
                    .clipShape(Capsule())
                    .padding(.top, 4)
            }
            .padding(.top, 8)
        }
        .frame(width: 240)
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .opacity(isPitchLocked ? 0.75 : 1.0)
    }
}

struct BuyerRowCard: View {
    let buyer: RegisteredBuyer
    var highestOffer: Double?
    var showUrgentBadge: Bool = false
    var isPitchLocked: Bool = false

    var body: some View {
        NavigationLink(destination: LiveOfferView(buyer: buyer)) {
            HStack {
                Image(systemName: "building.2.crop.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray.opacity(0.5))

                VStack(alignment: .leading, spacing: 4) {
                    Text(buyer.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Text("Needs \(buyer.typicalVolume)")
                        .font(.headline)
                    Text(buyer.locationName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    StarRatingBadge(rating: buyer.rating, count: buyer.ratingCount)
                }
                .padding(.leading, 4)

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("Highest Pitch")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(highestOffer.map { "Rs \(String(format: "%.0f", $0))" } ?? "—")
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                    Text(isPitchLocked ? "Pitched" : "Pitch Offer")
                        .font(.caption.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isPitchLocked ? Color.gray.opacity(0.3) : Color.orange)
                        .foregroundColor(isPitchLocked ? .secondary : .white)
                        .clipShape(Capsule())
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .opacity(isPitchLocked ? 0.75 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isPitchLocked)
        .allowsHitTesting(!isPitchLocked)
    }
}

struct UrgentPostCard: View {
    let post: UrgentRequest
    let buyer: RegisteredBuyer
    var highestOffer: Double?
    var isPitchLocked: Bool = false

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
                        .font(.headline)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption2)
                        Text(post.location)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("Highest Pitch")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(highestOffer.map { "Rs \(String(format: "%.0f", $0))" } ?? "—")
                        .font(.subheadline.bold())
                        .foregroundColor(isPitchLocked ? .secondary : urgencyColor)
                    Text(post.deadline, style: .relative)
                        .font(.caption2)
                        .foregroundColor(urgencyColor)
                    Text(isPitchLocked ? "Pitched" : "Pitch Offer")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isPitchLocked ? Color.gray.opacity(0.3) : urgencyColor)
                        .foregroundColor(isPitchLocked ? .secondary : .white)
                        .clipShape(Capsule())
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(urgencyColor.opacity(0.4), lineWidth: 1))
            .opacity(isPitchLocked ? 0.75 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isPitchLocked)
        .allowsHitTesting(!isPitchLocked)
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

