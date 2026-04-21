// Location: New-Pol-Mure/Features/MarketPlace/Views/LiveOfferView.swift

import SwiftUI
import MapKit

struct LiveOfferView: View {
    @State private var viewModel: LiveOfferViewModel
    @FocusState private var isInputFocused: Bool
    
    init(buyer: RegisteredBuyer, currentMarketPrice: Double = 120.0) {
        self._viewModel = State(initialValue: LiveOfferViewModel(buyer: buyer, currentMarketPrice: currentMarketPrice))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                
                OfferMapHeader(coordinate: viewModel.buyer.coordinate)
                
                VStack(alignment: .leading, spacing: 24) {
                    
                    BuyerDetailSection(buyer: viewModel.buyer)
                    
                    Divider()
                    
                    // NEW NAVIGATION: Safe placeholder to prevent build errors
                    NavigationLink(destination: Text("Analytics Dashboard Coming Soon").navigationTitle("Analytics")) {
                        HStack {
                            Image(systemName: "chart.xyaxis.line")
                            Text("Check Market Prices Before Pitching")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    OfferTerminal(viewModel: viewModel, isInputFocused: _isInputFocused)
                    
                    PresentationDebugToolsOffer(viewModel: viewModel)
                    
                }
                .padding(20)
            }
        }
        .navigationTitle("Pitch Details")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            isInputFocused = false
        }
    }
}

// MARK: - Reusable Subviews

struct OfferMapHeader: View {
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
                .foregroundStyle(.orange.opacity(0.3))
            
            Marker("Buyer Location", coordinate: coordinate)
                .tint(.orange)
        }
        .frame(height: 220)
        .mask(LinearGradient(gradient: Gradient(colors: [.black, .black, .black, .clear]), startPoint: .top, endPoint: .bottom))
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
            
            points.append(CLLocationCoordinate2D(latitude: (lat + dLat) * 180.0 / .pi,
                                                 longitude: (lon + dLon) * 180.0 / .pi))
        }
        return points
    }
}

struct BuyerDetailSection: View {
    let buyer: RegisteredBuyer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "building.2.crop.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray.opacity(0.5))
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(buyer.name)
                            .font(.title3.bold())
                        if buyer.isUrgent {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.secondary)
                        Text(buyer.locationName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text("Needs \(buyer.typicalVolume)")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .padding(.top, 8)
            
            HStack {
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(.orange)
                Text(buyer.isUrgent ? "Urgent Pitch Request" : "Accepting Pitches")
                    .font(.subheadline.bold())
            }
            .padding(10)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct OfferTerminal: View {
    @Bindable var viewModel: LiveOfferViewModel
    @FocusState var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Live Status Card
            VStack(spacing: 8) {
                Text(viewModel.isUnderbid ? "WARNING: CHEAPER OFFER SUBMITTED!" : "CURRENT LOWEST PITCH")
                    .font(.caption.bold())
                    .foregroundColor(viewModel.isUnderbid ? .red : .secondary)
                
                Text("Rs \(viewModel.currentLowestOffer, specifier: "%.2f")")
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(viewModel.isUnderbid ? .red : .green)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(viewModel.isUnderbid ? Color.red.opacity(0.1) : Color.green.opacity(0.05))
            .cornerRadius(16)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isUnderbid)
            
            // Stepper & Input Area
            HStack(spacing: 12) {
                Button(action: { viewModel.decrementOffer() }) {
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
                    
                    TextField("Offer", text: $viewModel.userOfferInput)
                        .keyboardType(.decimalPad)
                        .focused($isInputFocused)
                        .multilineTextAlignment(.center)
                        .font(.title2.bold())
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                Button(action: { viewModel.incrementOffer(by: 1) }) {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .frame(width: 50, height: 50)
                        .background(Color(UIColor.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
            
            HStack(spacing: 12) {
                ForEach([1, 5, 10], id: \.self) { amount in
                    Button(action: { viewModel.decrementOffer(bySpecificAmount: Double(amount)) }) {
                        Text("- Rs \(amount)")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }
                }
            }
            
            // Action Button
            Button(action: {
                if viewModel.sendPitch() {
                    isInputFocused = false
                }
            }) {
                Text("Send Pitch")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
}

struct PresentationDebugToolsOffer: View {
    @Bindable var viewModel: LiveOfferViewModel
    
    var body: some View {
        Button(action: {
            viewModel.simulateCheaperOffer()
        }) {
            Text("🔧 Simulate Competitor Cheaper Offer")
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

#Preview {
    NavigationStack {
        LiveOfferView(buyer: RegisteredBuyer(
            id: UUID().uuidString, // FIXED: Added missing 'id' argument
            name: "Nimal's Bakery",
            locationName: "Kaduwela Center",
            coordinate: CLLocationCoordinate2D(latitude: 6.9333, longitude: 79.9833),
            typicalVolume: "5K - 10K Nuts",
            // FIXED: Removed the extra 'volumeCapacity' argument
            rating: 4.7,
            isUrgent: true
        ))
    }
}
