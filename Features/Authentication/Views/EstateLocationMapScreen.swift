// Location: New-Pol-Mure/Features/Authentication/Views/EstateLocationMapScreen.swift

import SwiftUI
import MapKit
import CoreLocation

struct EstateLocationMapScreen: View {
    @Binding var estateLocation: CLLocationCoordinate2D
    @Binding var locationName: String
    @Environment(\.dismiss) var dismiss
    
    @State private var cameraPosition: MapCameraPosition
    @State private var searchQuery: String = ""
    @State private var isSearching: Bool = false
    @State private var currentZoomSpan: Double = 15000
    
    @State private var tempLocation: CLLocationCoordinate2D
    @State private var dynamicallyResolvedAddress: String = ""
    
    init(estateLocation: Binding<CLLocationCoordinate2D>, locationName: Binding<String>) {
        self._estateLocation = estateLocation
        self._locationName = locationName
        
        self._tempLocation = State(initialValue: estateLocation.wrappedValue)
        self._cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: estateLocation.wrappedValue,
            latitudinalMeters: 15000,
            longitudinalMeters: 15000
        )))
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                
                Map(position: $cameraPosition) {
                    MapCircle(center: tempLocation, radius: 5000)
                        .foregroundStyle(Color.orange.opacity(0.3))
                        .stroke(Color.orange, lineWidth: 2)
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
                        .foregroundColor(.orange)
                        .shadow(radius: 4)
                        .offset(y: -18)
                }
                
                VStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search Estate City or Road", text: $searchQuery)
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
                        Image(systemName: "hand.draw.fill").foregroundColor(.orange)
                        Text("Drag map to position your Estate Zone.").font(.caption.bold())
                    }
                    
                    if !dynamicallyResolvedAddress.isEmpty {
                        Text("Identified Area: \(dynamicallyResolvedAddress)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        estateLocation = tempLocation
                        if !dynamicallyResolvedAddress.isEmpty {
                            locationName = dynamicallyResolvedAddress
                        } else {
                            locationName = "Custom Estate Pin"
                        }
                        dismiss()
                    }) {
                        Text("Confirm Location")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
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
                let street = placemark.thoroughfare ?? ""
                let city = placemark.locality ?? placemark.subLocality ?? placemark.name ?? "Unknown Area"
                
                self.dynamicallyResolvedAddress = street.isEmpty ? city : "\(street), \(city)"
            } else {
                self.dynamicallyResolvedAddress = "Custom Estate Pin"
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
        let newSpan = zoomIn ? max(currentZoomSpan * 0.4, 500) : min(currentZoomSpan * 2.5, 500000)
        currentZoomSpan = newSpan
        withAnimation(.easeInOut(duration: 0.4)) {
            cameraPosition = .region(MKCoordinateRegion(center: tempLocation, latitudinalMeters: newSpan, longitudinalMeters: newSpan))
        }
    }
}
