import SwiftUI

struct SellerContractView: View {
    @Environment(\.dismiss) var dismiss

    @State private var viewModel: SellerContractViewModel
    @StateObject private var calendarManager = CalendarManager()

    init(contract: Contract) {
        _viewModel = State(initialValue: SellerContractViewModel(contract: contract))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        escrowSecurityCard
                        
                        ContractSummaryCard(buyerName: viewModel.buyerName, amount: viewModel.amount, volume: viewModel.buyerVolume)
                            .padding(.horizontal)


                        if viewModel.isDisputed {
                            SellerDisputeAlertCard(
                                reason:        viewModel.disputeReason,
                                notes:         viewModel.disputeNotes,
                                originalPrice: viewModel.originalPrice,
                                counterOffer:  viewModel.counterOffer,
                                onAccept:      { viewModel.acceptNewPrice() },
                                onCancel:      { viewModel.cancelContract() }
                            )
                            .padding(.horizontal)
                        }
                        
                        // WeatherKit Integration Warning Card (Seller Theme)
                        if !viewModel.isDisputed && viewModel.currentState == .buyerEnRoute {
                            // Assumes WeatherForecastCard is already in your project from the Buyer side
                            WeatherForecastCard(locationName: "Your Estate", date: viewModel.inspectionDate, themeColor: .orange)
                                .padding(.horizontal)
                        }
                        
                        // EventKit Logic: Show calendar only when buyer is en route (not after quality approved)
                        if !viewModel.isDisputed && viewModel.currentState == .buyerEnRoute && viewModel.inspectionDate > Date() {
                            calendarSchedulingCard
                        }
                        
                        SellerFSMTracker(currentState: viewModel.currentState)
                            .padding(.horizontal)
                        
                    }
                    .padding(.vertical, 20)
                    .padding(.bottom, 100)
                }
                
                stickyBottomAction
            }
            .navigationTitle("Contract \(viewModel.contractRef)")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showRatingSheet) {
                RatingSheet(
                    contractID:   viewModel.contractID,
                    reviewerID:   viewModel.sellerID,
                    reviewerName: viewModel.sellerDisplayName,
                    revieweeID:   viewModel.buyerID,
                    revieweeName: viewModel.buyerName,
                    role:         "seller"
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - UI Modules
    private var escrowSecurityCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lock.shield.fill").font(.title).foregroundColor(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("FUNDS SECURED IN ESCROW").font(.caption.bold()).foregroundColor(.green)
                    Text("The buyer's payment is locked and verified.").font(.caption2).foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.green.opacity(0.3), lineWidth: 1))
        .padding(.horizontal)
    }
    
    private var calendarSchedulingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock").font(.title2).foregroundColor(.orange)
                Text("Schedule Inspection").font(.headline)
                Spacer()
            }
            Text("Buyer is expected to arrive on **\(viewModel.inspectionDate.formatted(date: .abbreviated, time: .shortened))**.")
                .font(.subheadline).foregroundColor(.secondary)

            Button(action: {
                calendarManager.addInspectionToCalendar(
                    buyerName:        viewModel.buyerName,
                    contractId:       viewModel.contractRef,
                    amount:           viewModel.amount,
                    locationName:     viewModel.sellerLocationName,
                    sellerCoordinate: viewModel.sellerCoordinate,
                    date:             viewModel.inspectionDate
                )
            }) {
                HStack {
                    Image(systemName: calendarManager.eventAddedSuccessfully ? "checkmark.circle.fill" : "calendar.badge.plus")
                    Text(calendarManager.eventAddedSuccessfully ? "Added to Apple Calendar" : "Sync to Calendar").font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(calendarManager.eventAddedSuccessfully ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                .foregroundColor(calendarManager.eventAddedSuccessfully ? .green : .orange)
                .cornerRadius(12)
            }.disabled(calendarManager.eventAddedSuccessfully)

            if calendarManager.permissionDenied {
                Text("Calendar access denied. Enable it in iOS Settings → Privacy → Calendars.")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).padding(.horizontal)
    }
    
    @ViewBuilder
    private var stickyBottomAction: some View {
        VStack {
            Spacer()
            if viewModel.isDisputed {
                // Dispute blocks all handover actions
                Text("Please resolve the dispute above to continue.")
                    .font(.caption.bold())
                    .foregroundColor(.red)
                    .padding(.bottom, 30)

            } else if viewModel.currentState == .buyerEnRoute {
                // Buyer is en route but hasn't approved quality yet — handover locked
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                    Text("Waiting for buyer to approve quality…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 20)

            } else if viewModel.currentState == .qualityApproved {
                // Buyer approved quality — seller can now confirm handover
                Button(action: {
                    withAnimation { viewModel.confirmHandover() }
                }) {
                    if viewModel.isConfirmingHandover {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Label("Confirm Handover", systemImage: "box.truck.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(viewModel.isConfirmingHandover)
                .padding(.horizontal)
                .padding(.bottom, 20)
                .background(LinearGradient(gradient: Gradient(colors: [Color(UIColor.systemGroupedBackground).opacity(0.0), Color(UIColor.systemGroupedBackground)]), startPoint: .top, endPoint: .bottom).padding(.top, -20))

            } else if viewModel.currentState == .completed {
                Button(action: { viewModel.showRatingSheet = true }) {
                    Label("Rate \(viewModel.buyerName)", systemImage: "star.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                .background(LinearGradient(gradient: Gradient(colors: [Color(UIColor.systemGroupedBackground).opacity(0.0), Color(UIColor.systemGroupedBackground)]), startPoint: .top, endPoint: .bottom).padding(.top, -20))
            }
        }
    }
}


struct ContractSummaryCard: View {
    let buyerName: String
    let amount:    Double
    let volume:    String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Buyer Profile").font(.caption).foregroundColor(.secondary)
                Text(buyerName).font(.title3.bold())
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Contract Value").font(.caption).foregroundColor(.secondary)
                Text("Rs \(amount, specifier: "%.2f")").font(.headline.bold()).foregroundColor(.primary)
                if !volume.isEmpty {
                    Text("\(volume) Nuts").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(12)
    }
}

struct SellerDisputeAlertCard: View {
    let reason:        String
    let notes:         String
    let originalPrice: Double
    let counterOffer:  Double
    let onAccept:      () -> Void
    let onCancel:      () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.octagon.fill").foregroundColor(.red).font(.title2)
                Text("Buyer Initiated Dispute").font(.headline).foregroundColor(.red)
            }

            // Dynamic reason + notes
            VStack(alignment: .leading, spacing: 6) {
                if !reason.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Text("Issue:").font(.caption.bold()).foregroundColor(.secondary).frame(width: 44, alignment: .leading)
                        Text(reason).font(.subheadline)
                    }
                }
                if !notes.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Text("Notes:").font(.caption.bold()).foregroundColor(.secondary).frame(width: 44, alignment: .leading)
                        Text(notes).font(.subheadline).foregroundColor(.secondary)
                    }
                }
                if reason.isEmpty && notes.isEmpty {
                    Text("The buyer has raised a dispute and proposed a new price to complete the deal.")
                        .font(.subheadline)
                }
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("Original Bid").font(.caption).foregroundColor(.secondary)
                    Text("Rs \(originalPrice, specifier: "%.0f")").strikethrough().foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Counter-Offer").font(.caption).foregroundColor(.secondary)
                    Text("Rs \(counterOffer, specifier: "%.0f")").font(.title3.bold()).foregroundColor(.red)
                }
            }
            .padding().background(Color.red.opacity(0.05)).cornerRadius(8)

            HStack(spacing: 12) {
                Button(action: { withAnimation { onAccept() } }) {
                    Text("Accept New Price").font(.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.green).foregroundColor(.white).cornerRadius(10)
                }

                Button(action: { onCancel() }) {
                    Text("Cancel Contract").font(.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.red.opacity(0.1)).foregroundColor(.red).cornerRadius(10)
                }
            }
        }
        .padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.5), lineWidth: 1))
    }
}

struct SellerFSMTracker: View {
    let currentState: SellerContractState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Transaction Status").font(.headline).padding(.bottom, 16)

            SellerTimelineRow(title: "Escrow Secured",   subtitle: "Buyer funds are locked safely in the app.",       isCompleted: currentState.rawValue >= 1, isActive: currentState == .escrowSecured,   isLast: false)
            SellerTimelineRow(title: "Buyer En Route",   subtitle: "Waiting for buyer to arrive at the estate.",      isCompleted: currentState.rawValue >= 2, isActive: currentState == .buyerEnRoute,    isLast: false)
            SellerTimelineRow(title: "Quality Approved", subtitle: "Buyer inspected and signed off on goods.",        isCompleted: currentState.rawValue >= 3, isActive: currentState == .qualityApproved, isLast: false)
            SellerTimelineRow(title: "Escrow Released",  subtitle: "Funds are transferring to your bank.",            isCompleted: currentState == .completed,  isActive: currentState == .completed,       isLast: true)
        }
        .padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16)
    }
}

struct SellerTimelineRow: View {
    let title: String; let subtitle: String
    let isCompleted: Bool; let isActive: Bool
    let isLast: Bool

    @State private var pulsing = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .strokeBorder(isActive || isCompleted ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(isCompleted ? Color.green : Color.clear))

                    if isCompleted {
                        Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                    } else if isActive {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                            .scaleEffect(pulsing ? 1.2 : 0.8)
                            .opacity(pulsing ? 1.0 : 0.5)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulsing)
                            .onAppear { pulsing = true }
                    }
                }

                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? Color.green : Color.gray.opacity(0.2))
                        .frame(width: 2, height: 40)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.bold()).foregroundColor(isActive || isCompleted ? .primary : .secondary)
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
            .padding(.bottom, isLast ? 0 : 20)
        }
    }
}

#Preview {
    Text("Run on simulator to preview SellerContractView with live contract data.")
        .foregroundColor(.secondary)
        .padding()
}
