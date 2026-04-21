// Location: New-Pol-Mure/Features/Authentication/Views/BuyerFullScreenLocationPicker.swift

import SwiftUI
import MapKit
import CoreLocation

struct BuyerFullScreenLocationPicker: View {
    @Binding var buyerLocation: CLLocationCoordinate2D
    @Binding var locationName: String
    @Environment(\.dismiss) var dismiss
    
    @State private var cameraPosition: MapCameraPosition
    @State private var searchQuery: String = ""
    @State private var isSearching: Bool = false
    @State private var currentZoomSpan: Double = 15000
    
    @State private var tempLocation: CLLocationCoordinate2D
    @State private var dynamicallyResolvedCityName: String = ""
    
    init(buyerLocation: Binding<CLLocationCoordinate2D>, locationName: Binding<String>) {
        self._buyerLocation = buyerLocation
        self._locationName = locationName
        
        self._tempLocation = State(initialValue: buyerLocation.wrappedValue)
        self._cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: buyerLocation.wrappedValue,
            latitudinalMeters: 15000,
            longitudinalMeters: 15000
        )))
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                
                Map(position: $cameraPosition) {
                    MapCircle(center: tempLocation, radius: 5000)
                        .foregroundStyle(Color.blue.opacity(0.3))
                        .stroke(Color.blue, lineWidth: 2)
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    tempLocation = context.region.center
                    currentZoomSpan = context.region.span.latitudeDelta * 111000
                    reverseGeocode(coordinate: tempLocation)
                }
                .ignoresSafeArea()
                
                .overlay(alignment: .center) {
                    Image(systemName: "mappin")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.blue)
                        .shadow(radius: 4)
                        .offset(y: -18)
                }
                
                VStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search City (e.g. Kandy)", text: $searchQuery)
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
                    .padding(.bottom, 150)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "hand.draw.fill").foregroundColor(.blue)
                        Text("Drag map to position your location.").font(.caption.bold())
                    }
                    
                    if !dynamicallyResolvedCityName.isEmpty {
                        Text("Identified Area: \(dynamicallyResolvedCityName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        buyerLocation = tempLocation
                        if !dynamicallyResolvedCityName.isEmpty {
                            locationName = dynamicallyResolvedCityName
                        } else {
                            locationName = "Custom Location"
                        }
                        dismiss()
                    }) {
                        Text("Confirm Location")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
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
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                let name = placemark.locality ?? placemark.subLocality ?? placemark.name ?? "Unknown Area"
                self.dynamicallyResolvedCityName = name
            } else {
                self.dynamicallyResolvedCityName = "Custom Location"
            }
        }
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery + ", Sri Lanka"
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
            
            withAnimation(.easeInOut(duration: 1.0)) {
                tempLocation = coordinate
                cameraPosition = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 15000, longitudinalMeters: 15000))
            }
            reverseGeocode(coordinate: coordinate)
        }
    }
    
    private func zoomMap(in zoomIn: Bool) {
        let newSpan = zoomIn ? max(currentZoomSpan * 0.4, 1000) : min(currentZoomSpan * 2.5, 500000)
        currentZoomSpan = newSpan
        withAnimation(.easeInOut(duration: 0.4)) {
            cameraPosition = .region(MKCoordinateRegion(center: tempLocation, latitudinalMeters: newSpan, longitudinalMeters: newSpan))
        }
    }
}
