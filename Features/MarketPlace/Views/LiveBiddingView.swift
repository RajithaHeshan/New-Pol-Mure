

import SwiftUI
import MapKit

struct LiveBiddingView: View {
    @State private var viewModel: LiveBiddingViewModel

    @FocusState private var isInputFocused: Bool

    init(lot: HarvestLot) {
        _viewModel = State(initialValue: LiveBiddingViewModel(lot: lot))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                BiddingMapHeader(coordinate: viewModel.lot.coordinate)

                VStack(alignment: .leading, spacing: 24) {

                    HarvestDetailSection(lot: viewModel.lot)

                    Divider()

                    // MARK: - Navigation to Market Analytics (pre-selects zone matching this lot's location)
                    NavigationLink(destination: MarketAnalyticsView(
                        preselectedZone: CoconutZone.zone(
                            for: viewModel.lot.coordinate.latitude,
                            lng: viewModel.lot.coordinate.longitude
                        )
                    )) {
                        HStack {
                            Image(systemName: "chart.xyaxis.line")
                            Text("Check Market Prices Before Bidding")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }

                    BiddingTerminal(viewModel: viewModel, isInputFocused: _isInputFocused)


                }
                .padding(20)
            }
        }
        .navigationTitle("Auction Details")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            isInputFocused = false
        }
    }
}


struct BiddingMapHeader: View {    //location view
    let coordinate: CLLocationCoordinate2D

    // True when Firestore had no lat/lng — we skip the map entirely
    private var isValidCoordinate: Bool {
        coordinate.latitude != 0 || coordinate.longitude != 0
    }

    var body: some View {
        if isValidCoordinate {
            Map(position: .constant(.region(MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 8000,
                longitudinalMeters: 8000
            ))), interactionModes: []) {
                MapCircle(center: coordinate, radius: 2500)
                    .foregroundStyle(.blue.opacity(0.3))
                Marker("Estate Location", coordinate: coordinate)
                    .tint(.blue)
            }
            .frame(height: 220)
            .mask(
                LinearGradient(
                    gradient: Gradient(colors: [.black, .black, .black, .clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        } else {
            Image("Gemini_Generated_Image_bvc5lzbvc5lzbvc5")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()
                .mask(
                    LinearGradient(
                        gradient: Gradient(colors: [.black, .black, .black, .clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
}


struct HarvestDetailSection: View {
    let lot: HarvestLot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image("Gemini_Generated_Image_bvc5lzbvc5lzbvc5")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    if !lot.propertyName.isEmpty {
                        Text(lot.propertyName)
                            .font(.title3.bold())
                    }
                    if !lot.sellerInitial.isEmpty {
                        Text(lot.sellerInitial)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.secondary)
                        Text(lot.locationName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Text("\(lot.quantity) Coconuts")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .padding(.top, 4)

            if !lot.qualityGrade.isEmpty {
                Text(lot.qualityGrade)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.blue)
                Text("Ends ")
                    .font(.subheadline.bold())
                + Text(lot.endDate, style: .relative)
                    .font(.subheadline.bold())
            }
            .padding(10)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
}


struct BiddingTerminal: View {
    @Bindable var viewModel: LiveBiddingViewModel
    @FocusState var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 20) {

           
            VStack(spacing: 8) {
                Text(viewModel.isOutbid ? "WARNING: YOU WERE OUTBID!" : "CURRENT HIGHEST BID")
                    .font(.caption.bold())
                    .foregroundColor(viewModel.isOutbid ? .red : .secondary)

                Text("Rs \(viewModel.currentHighestBid, specifier: "%.2f")")
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(viewModel.isOutbid ? .red : .green)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(viewModel.isOutbid ? Color.red.opacity(0.1) : Color.green.opacity(0.05))
            .cornerRadius(16)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isOutbid)

            // MARK: - Stepper & Input Area
            HStack(spacing: 12) {
                Button(action: { viewModel.decrementBid() }) {
                    Image(systemName: "minus")
                        .font(.title2.bold())
                        .frame(width: 50, height: 50)
                        .background(Color(UIColor.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }

                HStack {
                    Text("Rs")
                        .font(.title2.bold())
                        .foregroundColor(.secondary)

                    TextField("Bid", text: $viewModel.userBidInput)
                        .keyboardType(.decimalPad)
                        .focused($isInputFocused)
                        .multilineTextAlignment(.center)
                        .font(.title2.bold())
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)

                Button(action: { viewModel.incrementBid(by: 1) }) {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .frame(width: 50, height: 50)
                        .background(Color(UIColor.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }

            // MARK: - Quick Increment Chips
            HStack(spacing: 12) {
                ForEach([1, 5, 10], id: \.self) { amount in
                    Button(action: { viewModel.incrementBid(by: Double(amount)) }) {
                        Text("+ Rs \(amount)")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                }
            }

            // Placed Bid Button
            Button(action: {
                viewModel.placeBid()
                isInputFocused = false
            }) {
                Group {
                    if viewModel.isPlacingBid {
                        ProgressView().tint(.white)
                    } else {
                        Text("Place Bid")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isPlacingBid)
        }
    }
}




#Preview {
    NavigationStack {
        LiveBiddingView(lot: HarvestLot(
            id: "preview-harvest-id",
            sellerID: "preview-seller-id",
            sellerInitial: "M. Silva",
            propertyName: "Kandy1",
            locationName: "William Gopallawa Mawatha, Kandy",
            coordinate: CLLocationCoordinate2D(latitude: 7.2906, longitude: 80.6337),
            quantity: 200,
            qualityGrade: "Standard (Local Market)",
            currentBid: 95.0,
            endDate: Date().addingTimeInterval(86400 * 7)
        ))
    }
}
