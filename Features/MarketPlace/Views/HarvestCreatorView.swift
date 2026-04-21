import SwiftUI
import MapKit

struct HarvestCreatorView: View {
    
    @State private var viewModel = HarvestCreatorViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                // Scrollable Content
                ScrollView {
                    VStack(spacing: 24) {
                        photoUploadSection
                        harvestDetailsSection
                        aiSuggestionSection
                        locationPrivacySection
                    }
                    .padding(.bottom, 100) // Padding for sticky button
                }
                
                // Sticky Action Button
                stickyBottomButton
            }
            .navigationTitle("New Listing")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - UI Sub-Components (Prevents Xcode Timeout)
    
    private var photoUploadSection: some View {
        Button(action: {}) {
            VStack(spacing: 12) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 32))
                Text("Add Photos")
                    .font(.headline)
            }
            .foregroundColor(.green)
            .frame(width: 160, height: 140)
            .background(Color.green.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .foregroundColor(.green.opacity(0.5))
            )
        }
        .padding(.top, 20)
    }
    
    private var harvestDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Harvest Details")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.leading, 16)
            
            VStack(spacing: 0) {
                HStack {
                    Text("Quantity")
                    Spacer()
                    TextField("e.g. 10000", text: $viewModel.quantity)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.primary)
                    Text("Nuts").foregroundColor(.secondary)
                }.padding()
                
                Divider().padding(.leading)
                
                HStack {
                    Text("Quality Grade")
                    Spacer()
                    Picker("Quality Grade", selection: $viewModel.qualityGrade) {
                        ForEach(viewModel.qualityOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }.tint(.blue)
                }.padding(.horizontal).padding(.vertical, 8)
                
                Divider().padding(.leading)
                
                HStack {
                    Text("Starting Price")
                    Spacer()
                    Text("Rs").foregroundColor(.secondary)
                    TextField("0.00", text: $viewModel.startingPrice)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.primary)
                }.padding()
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private var aiSuggestionSection: some View {
        Group {
            if viewModel.isReadyForSuggestion {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles").foregroundColor(.purple)
                        Text("Smart Market Suggestion").font(.subheadline.bold()).foregroundColor(.purple)
                    }
                    
                    Text("The current market average for \(viewModel.qualityGrade) in your area is **Rs \(viewModel.marketAverage, specifier: "%.2f")**.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Optimal Starting Bid").font(.caption).foregroundColor(.secondary)
                            Text("Rs \(viewModel.suggestedPrice, specifier: "%.2f")").font(.title3.bold()).foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation { viewModel.applySuggestion() }
                        }) {
                            Text("Apply Suggestion")
                                .font(.caption.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding()
                    .background(Color.purple.opacity(0.05))
                    .cornerRadius(12)
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purple.opacity(0.3), lineWidth: 1))
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private var locationPrivacySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location Privacy")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.leading, 16)
            
            Map(position: $viewModel.cameraPosition, interactionModes: []) {
                MapCircle(center: viewModel.estateLocation, radius: 5000)
                    .foregroundStyle(.green.opacity(0.3))
                Marker("Kurunegala", coordinate: viewModel.estateLocation)
                    .tint(.black)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("Buyers will only see a 5km fuzzy zone. Your exact farm location is hidden until Escrow is secured.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 4)
        }
        .padding(.horizontal)
    }
    
    private var stickyBottomButton: some View {
        VStack {
            Spacer()
            Button(action: {
                viewModel.launchAuction()
            }) {
                Group {
                    if viewModel.isLaunching {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Launch Auction")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isLaunching)
            .padding(.horizontal)
            .padding(.bottom, 20)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color(UIColor.systemGroupedBackground).opacity(0.0), Color(UIColor.systemGroupedBackground)]), startPoint: .top, endPoint: .bottom)
                    .padding(.top, -20)
            )
        }
        .alert("Auction Launched!", isPresented: $viewModel.launchSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your harvest lot is now live on the marketplace.")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.launchError != nil },
            set: { if !$0 { viewModel.launchError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.launchError ?? "")
        }
    }
}

#Preview {
    HarvestCreatorView()
}

