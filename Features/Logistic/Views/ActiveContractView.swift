

import SwiftUI
import MapKit

struct ActiveContractView: View {
    @State private var viewModel: ActiveContractViewModel
    @StateObject private var calendarManager = BuyerCalendarManager()

    init(contract: Contract) {
        _viewModel = State(initialValue: ActiveContractViewModel(contract: contract))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    ContractMapHeader(
                        buyerCoordinate: viewModel.buyerCoordinate,
                        sellerCoordinate: viewModel.sellerCoordinate,
                        isRevealed: viewModel.isLocationRevealed
                    )

                    SellerContactCard(name: viewModel.sellerName, phone: viewModel.sellerPhone)
                        .padding(.horizontal)

                    
                    if viewModel.isLocationRevealed {
                        WeatherForecastCard(locationName: "Estate Area", date: viewModel.inspectionDate, themeColor: .blue)
                            .padding(.horizontal)
                    }

                   
                    if viewModel.isLocationRevealed {
                        calendarSchedulingCard
                            .padding(.horizontal)
                    }

                    Divider().padding(.horizontal)

                    FSMTimelineTracker(currentState: viewModel.currentState, isPulsing: viewModel.isPulsing)
                        .padding(.horizontal)

                    ContextualActionArea(viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.top, 10)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Contract \(viewModel.contractRef)")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    viewModel.isPulsing = true
                }
            }
            .sheet(isPresented: $viewModel.showDisputeModal) {  //dispite 
                DisputeModalView(contractID: viewModel.contractID, originalBid: viewModel.amount)
                    .presentationDetents([.large, .medium])
            }
            .sheet(isPresented: $viewModel.showDatePicker) {
                InspectionDatePickerSheet(viewModel: viewModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $viewModel.showRatingSheet) {
                RatingSheet(
                    contractID:   viewModel.contractID,
                    reviewerID:   viewModel.buyerID,
                    reviewerName: viewModel.buyerDisplayName,
                    revieweeID:   viewModel.sellerID,
                    revieweeName: viewModel.sellerName,
                    role:         "buyer"
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }


    //after reveal location tap calender event create
    
    private var calendarSchedulingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock").font(.title2).foregroundColor(.blue)
                Text("Schedule Pick-up").font(.headline)
                Spacer()
            }

           
            Button(action: {
                calendarManager.eventAddedSuccessfully = false   // allow re-schedule after changing date/reminder
                viewModel.showDatePicker = true
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        let loc = viewModel.sellerLocationName.isEmpty ? "" : ", \(viewModel.sellerLocationName)"
                        Text("Add a reminder to leave for **\(viewModel.sellerName)**'s estate\(loc) on")
                            .font(.subheadline).foregroundColor(.secondary)
                        Text(viewModel.inspectionDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline.bold()).foregroundColor(.blue)
                    }
                    Spacer()
                    Image(systemName: "pencil.circle").foregroundColor(.blue).font(.title3)
                }
            }
            .buttonStyle(.plain)

            Button(action: {
                let fireDate = viewModel.inspectionDate.addingTimeInterval(viewModel.selectedReminderOffset)
                print("📲 Add to Calendar tapped — inspectionDate: \(viewModel.inspectionDate), reminderOffset: \(viewModel.selectedReminderOffset)s, notificationFiresAt: \(fireDate), secondsUntilFire: \(fireDate.timeIntervalSinceNow)s")
                calendarManager.addInspectionToCalendar(
                    sellerName:       viewModel.sellerName,
                    contractId:       viewModel.contractRef,
                    amount:           viewModel.amount,
                    sellerYield:      viewModel.sellerYield,
                    locationName:     viewModel.sellerLocationName,
                    sellerCoordinate: viewModel.sellerCoordinate,
                    date:             viewModel.inspectionDate,
                    reminderOffset:   viewModel.selectedReminderOffset
                )
            }) {
                HStack {
                    Image(systemName: calendarManager.eventAddedSuccessfully ? "checkmark.circle.fill" : "calendar.badge.plus")
                    Text(calendarManager.eventAddedSuccessfully ? "Added to Calendar" : "Add to Calendar").font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(calendarManager.eventAddedSuccessfully ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                .foregroundColor(calendarManager.eventAddedSuccessfully ? .green : .blue)
                .cornerRadius(12)
            }.disabled(calendarManager.eventAddedSuccessfully)





            if calendarManager.permissionDenied {
                Text("Permission denied. Please enable Calendar access in iOS Settings.")
                    .font(.caption2)
                    .foregroundColor(.red)
            }

            if calendarManager.reminderDateExpired {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    Text("Reminder time has passed. Tap the date above to pick a new inspection time.")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                .onTapGesture {
                    calendarManager.eventAddedSuccessfully = false
                    calendarManager.reminderDateExpired    = false
                    viewModel.showDatePicker = true
                }
            }
        }
        .padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}






struct WeatherForecastCard: View {
    let locationName: String
    let date: Date
    let themeColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "cloud.heavyrain.fill").font(.largeTitle).foregroundColor(themeColor)
            VStack(alignment: .leading, spacing: 4) {
                Text("Logistics Weather Alert").font(.subheadline.bold()).foregroundColor(themeColor)
                Text("Heavy rain expected in \(locationName) during the scheduled inspection time. Drive carefully.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(themeColor.opacity(0.1))
        .cornerRadius(16)
    }
}


//map show exact location with location distance

struct ContractMapHeader: View {
    let buyerCoordinate: CLLocationCoordinate2D
    let sellerCoordinate: CLLocationCoordinate2D
    let isRevealed: Bool

    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var displayETA: String = ""
    @State private var displayDistance: String = ""
    @State private var isCalculatingRoute = false
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, interactionModes: isRevealed ? .all : []) {
                if isRevealed {
                    Marker("My Location", coordinate: buyerCoordinate).tint(.blue)
                    Marker("Estate Entrance", coordinate: sellerCoordinate).tint(.red)
                    if !routeCoordinates.isEmpty {
                        MapPolyline(coordinates: routeCoordinates)
                            .stroke(.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    }
                } else {
                    MapCircle(center: sellerCoordinate, radius: 4000)
                        .foregroundStyle(.blue.opacity(0.3))
                }
            }
            .frame(height: isRevealed ? 300 : 220)
            .mask(LinearGradient(gradient: Gradient(colors: [.black, .black, .black, .clear]), startPoint: .top, endPoint: .bottom))
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isRevealed)

            if !displayETA.isEmpty && isRevealed {
                HStack {
                    Image(systemName: "car.fill")
                    Text(displayETA).font(.headline)
                    Text("•")
                    Text(displayDistance)
                }
                .padding(8).background(.thickMaterial).cornerRadius(8).padding(.top, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            } else if isCalculatingRoute {
                ProgressView().padding(8).background(.thickMaterial).cornerRadius(8).padding(.top, 16)
            }
        }
        .onAppear {
            
            cameraPosition = .region(MKCoordinateRegion(center: sellerCoordinate, latitudinalMeters: 8000, longitudinalMeters: 8000))
            
            if isRevealed { Task { await calculateRoute() } }
        }
        .onChange(of: isRevealed) { revealed in
            if revealed { Task { await calculateRoute() } }
        }
       
        .onChange(of: sellerCoordinate.latitude) { _ in
            cameraPosition = .region(MKCoordinateRegion(center: sellerCoordinate, latitudinalMeters: 8000, longitudinalMeters: 8000))
            if isRevealed { Task { await calculateRoute() } }
        }
        .onChange(of: buyerCoordinate.latitude) { _ in
            if isRevealed { Task { await calculateRoute() } }
        }
    }

    private func calculateRoute() async {
        isCalculatingRoute = true
        routeCoordinates = []
        displayETA = ""
        displayDistance = ""

        let request = MKDirections.Request()
        request.source      = MKMapItem(placemark: MKPlacemark(coordinate: buyerCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: sellerCoordinate))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        do {
            let response = try await directions.calculate()
            if let fastestRoute = response.routes.first {
                applyRouteData(
                    coordinates: getCoordinates(from: fastestRoute.polyline),
                    eta: formatETA(fastestRoute.expectedTravelTime),
                    distance: String(format: "%.1f km", fastestRoute.distance / 1000)
                )
            }
        } catch {
            print("MKDirections failed — using fallback path between real coordinates.")
            // Fallback still uses real buyer/seller endpoints, only midpoints are approximated
            let fallbackPath = [
                buyerCoordinate,
                CLLocationCoordinate2D(latitude: (buyerCoordinate.latitude + sellerCoordinate.latitude) / 2 - 0.05,
                                       longitude: (buyerCoordinate.longitude + sellerCoordinate.longitude) / 2),
                sellerCoordinate
            ]
            applyRouteData(coordinates: fallbackPath, eta: "Calculating...", distance: String(format: "%.1f km", haversineKm(from: buyerCoordinate, to: sellerCoordinate)))
        }
    }



    @MainActor
    private func applyRouteData(coordinates: [CLLocationCoordinate2D], eta: String, distance: String) {
        withAnimation(.easeInOut(duration: 1.0)) {
            self.routeCoordinates = coordinates
            self.displayETA       = eta
            self.displayDistance  = distance
            self.isCalculatingRoute = false
            self.cameraPosition   = .automatic
        }
    }

    private func getCoordinates(from polyline: MKPolyline) -> [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: polyline.pointCount)
        polyline.getCoordinates(&coords, range: NSRange(location: 0, length: polyline.pointCount))
        return coords
    }

    private func formatETA(_ timeInterval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: timeInterval) ?? ""
    }

    
    //harvest calculation 

    private func haversineKm(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let R = 6371.0
        let dLat = (b.latitude  - a.latitude)  * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let sinLat = sin(dLat / 2), sinLon = sin(dLon / 2)
        let c = 2 * atan2(sqrt(sinLat*sinLat + cos(a.latitude * .pi/180) * cos(b.latitude * .pi/180) * sinLon*sinLon),
                          sqrt(1 - sinLat*sinLat - cos(a.latitude * .pi/180) * cos(b.latitude * .pi/180) * sinLon*sinLon))
        return R * c
    }
}

//name and phone icon 

struct SellerContactCard: View {
    let name: String
    let phone: String
    
    var body: some View {
        HStack {
            Image(systemName: "person.crop.circle.badge.checkmark").resizable().scaledToFit().frame(width: 50, height: 50).foregroundColor(.green)
            VStack(alignment: .leading, spacing: 4) {
                Text("Seller Unlocked").font(.caption).foregroundColor(.secondary)
                Text(name).font(.title3.bold())
            }.padding(.leading, 8)
            Spacer()
            Button(action: {
                if let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
            }) {
                Image(systemName: "phone.circle.fill").resizable().frame(width: 44, height: 44).foregroundColor(.green)
            }
        }
        .padding().background(Color(UIColor.secondarySystemBackground)).cornerRadius(16)
    }
}


//logistic tracker 


struct FSMTimelineTracker: View {
    let currentState: ContractState
    let isPulsing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Logistics Tracker").font(.headline).padding(.bottom, 16)
            TimelineRow(title: "Contract Created", subtitle: "Bid accepted. Awaiting fund lock.", isCompleted: currentState.rawValue >= 0, isActive: currentState == .bidAccepted, isPulsing: isPulsing, isLast: false)
            TimelineRow(title: "Funds Locked", subtitle: "Payment secured in escrow. Seller notified.", isCompleted: currentState.rawValue > 1, isActive: currentState == .fundsLocked, isPulsing: isPulsing, isLast: false)
            TimelineRow(title: "Quality Inspection", subtitle: "Travel to estate to verify coconut quality.", isCompleted: currentState.rawValue > 2, isActive: currentState == .inspectionPending, isPulsing: isPulsing, isLast: false)
            TimelineRow(title: "Payment Released", subtitle: "Funds transferred to seller after approval.", isCompleted: currentState.rawValue > 3, isActive: currentState == .paymentPending, isPulsing: isPulsing, isLast: true)
        }
        .padding().background(Color(UIColor.secondarySystemBackground)).cornerRadius(16)
    }
}


//logistic tracker timeline change 

struct TimelineRow: View {
    let title: String; let subtitle: String
    let isCompleted: Bool; let isActive: Bool; let isPulsing: Bool; let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().strokeBorder(isActive ? Color.blue : (isCompleted ? Color.green : Color.gray.opacity(0.3)), lineWidth: 2).frame(width: 24, height: 24).background(Circle().fill(isCompleted ? Color.green : Color.clear))
                    if isCompleted && !isActive { Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                    } else if isActive { Circle().fill(Color.blue).frame(width: 12, height: 12).scaleEffect(isPulsing ? 1.2 : 0.8).opacity(isPulsing ? 1.0 : 0.5) }
                }
                if !isLast { Rectangle().fill(isCompleted && !isActive ? Color.green : Color.gray.opacity(0.2)).frame(width: 2, height: 40) }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.bold()).foregroundColor(isActive ? .primary : (isCompleted ? .primary : .secondary))
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }.padding(.bottom, isLast ? 0 : 20)
        }
    }
}


//Escrow payment Due cardmenu 

struct ContextualActionArea: View {
    @Bindable var viewModel: ActiveContractViewModel

    var body: some View {
        VStack(spacing: 12) {

         
            if viewModel.currentState == .bidAccepted {
                EscrowSummaryCard(amount: viewModel.amount, sellerName: viewModel.sellerName)

                Button(action: { viewModel.lockFunds() }) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                        Text("Lock Funds in Escrow")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }

      
              //after locahfund escrow

            } else if viewModel.currentState == .fundsLocked {
                FundsLockedBanner()

                Button(action: { viewModel.showDatePicker = true }) {
                    HStack {
                        Image(systemName: "calendar").foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Inspection Date").font(.caption).foregroundColor(.secondary)
                            Text(viewModel.pendingPickerDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline.bold()).foregroundColor(.blue)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.06))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)

                Button(action: { viewModel.revealLocation() }) {
                    Label("Reveal Exact Location", systemImage: "location.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }


            //approve or dispute

            } else if viewModel.currentState == .inspectionPending && viewModel.isDisputePending {
                // Dispute submitted — waiting for seller to respond
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.badge.exclamationmark.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dispute Submitted")
                                .font(.subheadline.bold())
                                .foregroundColor(.orange)
                            Text("Waiting for the seller to review your dispute and respond.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.25), lineWidth: 1))
                }

            } else if viewModel.currentState == .inspectionPending {
                Button(action: { viewModel.releaseFundsSimulation() }) {
                    Label("Approve Quality & Release Funds", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                Button(action: { viewModel.showDisputeModal = true }) {
                    Text("Dispute / Renegotiate")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                }

         
            } else if viewModel.currentState == .paymentPending {
                HStack(spacing: 12) {
                    ProgressView()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quality Approved")
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                        Text("Waiting for seller to confirm handover…")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.06))
                .cornerRadius(12)

          
            } else if viewModel.currentState == .completed {
                VStack(spacing: 12) {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                        Text("Transaction Complete")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text("Escrow funds have been successfully transferred to the seller's account.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)

                    Button(action: { viewModel.showRatingSheet = true }) {
                        Label("Rate \(viewModel.sellerName)", systemImage: "star.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// Escrow Summary Card 
private struct EscrowSummaryCard: View {
    let amount: Double
    let sellerName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "banknote.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Escrow Payment Due")
                        .font(.headline)
                    Text("Funds are held securely until quality is approved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Divider()
            HStack {
                Text("Amount to Lock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Rs \(String(format: "%.0f", amount))")
                    .font(.title3.bold())
                    .foregroundColor(.blue)
            }
            HStack {
                Text("Recipient (on approval)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(sellerName)
                    .font(.subheadline.bold())
            }
            HStack {
                Text("Platform Fee (2%)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Rs \(String(format: "%.0f", amount * 0.02))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue.opacity(0.2), lineWidth: 1))
    }
}


//green color banner 

private struct FundsLockedBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.title2)
                .foregroundColor(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Funds Secured in Escrow")
                    .font(.subheadline.bold())
                    .foregroundColor(.green)
                Text("Payment is locked and will be released to the seller once you approve quality.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.green.opacity(0.08))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.25), lineWidth: 1))
    }
}




//remainders for calneder 

private struct ReminderOption: Identifiable {
    let id:     Int
    let label:  String
    let offset: TimeInterval   // negative seconds before event
}

private let reminderOptions: [ReminderOption] = [
    ReminderOption(id: 0, label: "2 minutes before",  offset: -120),
    ReminderOption(id: 1, label: "15 minutes before", offset: -900),
    ReminderOption(id: 2, label: "1 hour before",     offset: -3600),
    ReminderOption(id: 3, label: "24 hours before",   offset: -86400)
]



//inspection date time picker 

struct InspectionDatePickerSheet: View {
    @Bindable var viewModel: ActiveContractViewModel
    @Environment(\.dismiss) private var dismiss

   
    @State private var localDate:           Date
    @State private var localReminderOffset: TimeInterval

    init(viewModel: ActiveContractViewModel) {
        self.viewModel            = viewModel
        self._localDate           = State(initialValue: viewModel.pendingPickerDate)
        self._localReminderOffset = State(initialValue: viewModel.selectedReminderOffset)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                   
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Choose Inspection Date & Time")
                            .font(.headline)
                        let loc = viewModel.sellerLocationName.isEmpty ? "" : ", \(viewModel.sellerLocationName)"
                        Text("Select when you plan to arrive at **\(viewModel.sellerName)**'s estate\(loc).")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

             
                    DatePicker(
                        "Date",
                        selection: $localDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(.blue)
                    .padding(.horizontal)

                    Divider().padding(.horizontal)

                    // Time — wheel so it's fully visible and easy to scroll
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Time")
                            .font(.subheadline.bold())
                            .padding(.horizontal)

                        DatePicker(
                            "Time",
                            selection: $localDate,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .tint(.blue)
                    }

                    Divider().padding(.horizontal)

                   
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bell.badge").foregroundColor(.blue)
                            Text("Remind Me Before")
                                .font(.subheadline.bold())
                        }
                        .padding(.horizontal)

                        VStack(spacing: 8) {
                            ForEach(reminderOptions) { option in
                                Button(action: { localReminderOffset = option.offset }) {
                                    HStack {
                                        Text(option.label)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if localReminderOffset == option.offset {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        localReminderOffset == option.offset
                                            ? Color.blue.opacity(0.08)
                                            : Color(UIColor.secondarySystemGroupedBackground)
                                    )
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Confirm button
                    Button(action: {
                        viewModel.pendingPickerDate       = localDate
                        viewModel.inspectionDate          = localDate
                        viewModel.selectedReminderOffset  = localReminderOffset
                        if viewModel.isLocationRevealed {
                            viewModel.updateInspectionDate(localDate)
                        }
                        dismiss()
                    }) {
                        Text("Confirm  \(localDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .padding(.top, 20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Schedule Pick-up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ActiveContractPreviewWrapper()
}


private struct ActiveContractPreviewWrapper: View {
    var body: some View {
       
        Text("Run on simulator to preview ActiveContractView with live data.")
            .foregroundColor(.secondary)
            .padding()
    }
}
