

import SwiftUI
import MapKit

struct BuyerRegistrationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var viewModel = BuyerRegistrationViewModel()
    
   
    @State private var inlineCameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609),
        latitudinalMeters: 5000,
        longitudinalMeters: 5000
    ))
    
    var body: some View {
        Form {
           
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image("Gemini_Generated_Image_l5uvm3l5uvm3l5uv")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                        
                        Text("Default Profile Selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            
          
            Section(header: Text("Account Details")) {
                TextField("Full Name / Business Name", text: $viewModel.fullName)
                    .textContentType(.name)
                
                TextField("Email Address", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                
                TextField("Phone Number", text: $viewModel.phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                
                SecureField("Create Password", text: $viewModel.password)
                    .textContentType(.newPassword)
            }
            
           
            Section(header: Text("Business Profile")) {
                Picker("Business Type", selection: $viewModel.businessType) {
                    ForEach(viewModel.businessTypes, id: \.self) {
                        Text($0)
                    }
                }
                .tint(.green)
                
                if viewModel.businessType == "Other" {
                    TextField("Specify Business Type", text: $viewModel.customBusinessType)
                }
                
                HStack {
                    Text("Typical Volume")
                    Spacer()
                    TextField("e.g. 5000", text: $viewModel.typicalVolume)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .foregroundColor(.green)
                    
                    Picker("", selection: $viewModel.volumeUnit) {
                        ForEach(viewModel.volumeUnits, id: \.self) {
                            Text($0)
                        }
                    }
                    .labelsHidden()
                }
            }
            
           
            Section(header: Text("Sourcing Location")) {
                ZStack {
                   
                    Map(position: $inlineCameraPosition, interactionModes: []) {
                        MapCircle(center: viewModel.buyerLocation, radius: 2000)
                            .foregroundStyle(.blue.opacity(0.3))
                        Marker("Zone", coordinate: viewModel.buyerLocation)
                            .tint(.blue)
                    }
                    .frame(height: 140)
                    
                  
                    Button(action: { viewModel.isFullScreenMapPresented = true }) {
                        Color.clear
                    }
                }
                .listRowInsets(EdgeInsets())
                .overlay(alignment: .topTrailing) {
                   
                    Button(action: { viewModel.isFullScreenMapPresented = true }) {
                        Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                            .frame(width: 32, height: 32)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding(12)
                    .buttonStyle(PlainButtonStyle())
                }
                
               
                HStack {
                    Text("Selected Zone:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(viewModel.locationName)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }
            }
            
            
            Section {
                Button(action: {
                    viewModel.registerBuyer(onSuccess: {
                        dismiss()
                    })
                }) {
                    Text("Create Buyer Account")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(viewModel.isFormValid ? Color.green : Color(UIColor.systemGray4))
                        .foregroundColor(viewModel.isFormValid ? .white : Color(UIColor.systemGray))
                        .cornerRadius(14)
                }
                .disabled(!viewModel.isFormValid)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Join as a Buyer")
        .navigationBarTitleDisplayMode(.inline)
       
        .sheet(isPresented: $viewModel.isFullScreenMapPresented) {
            BuyerFullScreenLocationPicker(buyerLocation: $viewModel.buyerLocation, locationName: $viewModel.locationName)
        }
       
        .onChange(of: viewModel.locationName) { _, _ in
            inlineCameraPosition = .region(MKCoordinateRegion(
                center: viewModel.buyerLocation,
                latitudinalMeters: 5000,
                longitudinalMeters: 5000
            ))
        }
    }
}

#Preview {
    BuyerRegistrationView()
}
