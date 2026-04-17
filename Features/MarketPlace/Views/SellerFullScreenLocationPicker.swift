// Location: New-Pol-Mure/Features/SellerDashboard/Views/SellerFullScreenLocationPicker.swift

import SwiftUI
import MapKit

struct SellerFullScreenLocationPicker: View {
    @Binding var searchCenter: CLLocationCoordinate2D
    @Binding var searchRadius: Double
    let buyers: [RegisteredBuyer]
    
    @Environment(\.dismiss) var dismiss
    
    @State private var cameraPosition: MapCameraPosition
    @State private var searchQuery: String = ""
    @State private var isSearching: Bool = false
    @State private var currentZoomSpan: Double
    
    init(searchCenter: Binding<CLLocationCoordinate2D>, searchRadius: Binding<Double>, buyers: [RegisteredBuyer]) {
        self._searchCenter = searchCenter
        self._searchRadius = searchRadius
        self.buyers = buyers
        
        let initialSpan = searchRadius.wrappedValue * 3000
        self._currentZoomSpan = State(initialValue: initialSpan)
        self._cameraPosition = State(initialValue: .region(MKCoordinateRegion(center: searchCenter.wrappedValue, latitudinalMeters: initialSpan, longitudinalMeters: initialSpan)))
    }
    
    var activeBuyers: [RegisteredBuyer] {
        let centerLocation = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)
        return buyers.filter { buyer in
            let buyerLocation = CLLocation(latitude: buyer.coordinate.latitude, longitude: buyer.coordinate.longitude)
            return (buyerLocation.distance(from: centerLocation) / 1000.0) <= searchRadius
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $cameraPosition) {
                    MapCircle(center: searchCenter, radius: searchRadius * 1000)
                        .foregroundStyle(.orange.opacity(0.3))
                        .stroke(.orange, lineWidth: 2)
                    
                    ForEach(activeBuyers) { buyer in
                        Annotation(buyer.name, coordinate: buyer.coordinate) {
                            VStack {
                                Image(systemName: "building.2.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.orange)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                }
                .onMapCameraChange(frequency: .continuous) { context in
                    searchCenter = context.region.center
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    currentZoomSpan = context.region.span.latitudeDelta * 111000
                }
                .ignoresSafeArea()
                
                VStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.orange)
                        .background(Circle().fill(Color.white).frame(width: 28, height: 28))
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                        .offset(y: -18)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .allowsHitTesting(false)
                
                VStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search for a town (e.g. Kandy)", text: $searchQuery)
                            .submitLabel(.search)
                            .onSubmit { performSearch() }
                        
                        if isSearching {
                            ProgressView().scaleEffect(0.8)
                        } else if !searchQuery.isEmpty {
                            Button(action: { searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(.thickMaterial)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    Spacer()
                }
                
                VStack {
                    Spacer()
                    VStack(spacing: 0) {
                        Button(action: { zoomMap(in: true) }) {
                            Image(systemName: "plus").font(.title3.bold()).frame(width: 44, height: 44).background(.thickMaterial).foregroundColor(.primary)
                        }
                        Divider().frame(width: 44)
                        Button(action: { zoomMap(in: false) }) {
                            Image(systemName: "minus").font(.title3.bold()).frame(width: 44, height: 44).background(.thickMaterial).foregroundColor(.primary)
                        }
                    }
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.trailing, 16)
                    .padding(.bottom, 180)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "hand.draw.fill").foregroundColor(.orange)
                        Text("Drag map or search to reposition.").font(.caption.bold())
                    }
                    HStack {
                        Text("\(Int(searchRadius)) km").font(.headline).foregroundColor(.orange)
                        Slider(value: $searchRadius, in: 1...50, step: 1).tint(.orange)
                    }
                    Button(action: { dismiss() }) {
                        Text("Apply Search Area").font(.headline).frame(maxWidth: .infinity).padding().background(Color.orange).foregroundColor(.white).cornerRadius(12)
                    }
                }
                .padding()
                .background(.thickMaterial)
                .cornerRadius(20)
                .padding()
                .shadow(radius: 10)
            }
            .navigationTitle("Adjust Search Area")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        request.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 7.8731, longitude: 80.7718), latitudinalMeters: 500000, longitudinalMeters: 500000)
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
            withAnimation(.easeInOut(duration: 1.0)) {
                searchCenter = coordinate
                cameraPosition = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: searchRadius * 3000, longitudinalMeters: searchRadius * 3000))
            }
        }
    }
    
    private func zoomMap(in zoomIn: Bool) {
        let newSpan = zoomIn ? max(currentZoomSpan * 0.4, 1000) : min(currentZoomSpan * 2.5, 500000)
        currentZoomSpan = newSpan
        withAnimation(.easeInOut(duration: 0.4)) {
            cameraPosition = .region(MKCoordinateRegion(center: searchCenter, latitudinalMeters: newSpan, longitudinalMeters: newSpan))
        }
    }
}

