

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

                    // MARK: - Navigation to Market Analytics
                    NavigationLink(destination: MarketAnalyticsView()) {
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

                    PresentationDebugTools(viewModel: viewModel)
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

// MARK: - Bidding Map Header
struct BiddingMapHeader: View {
    let coordinate: CLLocationCoordinate2D

    @State private var cameraPosition: MapCameraPosition

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        let customCamera = MapCamera(
            centerCoordinate: coordinate,
            distance: 6000,
            heading: 45,
            pitch: 60
        )
        self._cameraPosition = State(initialValue: .camera(customCamera))
    }

    var body: some View {
        Map(position: $cameraPosition, interactionModes: []) {
            MapPolygon(coordinates: createCylinderBase(center: coordinate, radiusMeters: 2500))
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
    }

    private func createCylinderBase(center: CLLocationCoordinate2D, radiusMeters: Double) -> [CLLocationCoordinate2D] {
        let earthRadius = 6378100.0
        let lat = center.latitude * .pi / 180.0
        let lon = center.longitude * .pi / 180.0

        var points: [CLLocationCoordinate2D] = []
        for i in 0..<36 {
            let angle = Double(i) * 10.0 * .pi / 180.0
            let dLat = (radiusMeters * cos(angle)) / earthRadius
            let dLon = (radiusMeters * sin(angle)) / (earthRadius * cos(lat))
            points.append(CLLocationCoordinate2D(
                latitude: (lat + dLat) * 180.0 / .pi,
                longitude: (lon + dLon) * 180.0 / .pi
            ))
        }
        return points
    }
}

// MARK: - Harvest Detail Section
struct HarvestDetailSection: View {
    let lot: HarvestLot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray.opacity(0.5))

                VStack(alignment: .leading) {
                    Text(lot.sellerInitial)
                        .font(.title3.bold())
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
                .padding(.top, 8)

            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.blue)
                Text("Auction closes in 24 Hours")
                    .font(.subheadline.bold())
            }
            .padding(10)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Bidding Terminal
struct BiddingTerminal: View {
    @Bindable var viewModel: LiveBiddingViewModel
    @FocusState var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 20) {

            // MARK: - Live Status Card
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

            // MARK: - Place Bid Button
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

// MARK: - Presentation Debug Tools
struct PresentationDebugTools: View {
    @Bindable var viewModel: LiveBiddingViewModel

    var body: some View {
        Button(action: { viewModel.simulateOutbid() }) {
            Text("🔧 Simulate WebSocket Outbid Event")
                .font(.caption.bold())
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.top, 40)
    }
}

// MARK: - Temporary Placeholder
struct MarketAnalyticsView: View {
    var body: some View {
        Text("Market Analytics Placeholder")
            .navigationTitle("Market Prices")
    }
}

#Preview {
    NavigationStack {
        LiveBiddingView(lot: HarvestLot(
            id: "preview-seller-id",
            sellerInitial: "M. Silva",
            locationName: "Madampe",
            coordinate: CLLocationCoordinate2D(latitude: 7.4984, longitude: 79.8441),
            quantity: 10000,
            currentBid: 95.0,
            endDate: Date().addingTimeInterval(86400)
        ))
    }
}
