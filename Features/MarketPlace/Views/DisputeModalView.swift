// Location: New-Pol-Mure/Features/Marketplace/Views/DisputeModalView.swift

import SwiftUI

struct DisputeModalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var viewModel: DisputeModalViewModel
    @FocusState private var isInputFocused: Bool

    // Local state for the form fields — avoids @Observable binding issues
    @State private var selectedReason: String = "Quality (Rotten/Spoiled)"
    @State private var additionalNotes: String = ""
    @State private var counterOfferAmount: String = ""

    init(contractID: String = "", originalBid: Double = 120.00) {
        _viewModel = State(initialValue: DisputeModalViewModel(contractID: contractID, originalBid: originalBid))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Select Issue", selection: $selectedReason) {
                        ForEach(viewModel.reasons, id: \.self) { reason in
                            Text(reason).tag(reason)
                        }
                    }
                    .pickerStyle(.menu)

                    TextField("Add specific details (Optional)", text: $additionalNotes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($isInputFocused)
                } header: {
                    Text("What is the problem?")
                } footer: {
                    Text("Provide clear reasons so the seller can understand your dispute.")
                }

                Section {
                    HStack {
                        Text("Original Bid")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Rs \(viewModel.originalBid, specifier: "%.2f")")
                            .strikethrough()
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("New Counter-Offer")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("Rs")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $counterOfferAmount)
                            .keyboardType(.decimalPad)
                            .focused($isInputFocused)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.blue)
                            .font(.headline)
                    }
                } header: {
                    Text("Renegotiate Price")
                }

                Section {
                    Button(action: {
                        isInputFocused = false
                        viewModel.submitCounterOffer(
                            reason: selectedReason,
                            notes: additionalNotes,
                            counterOffer: counterOfferAmount,
                            onSuccess: { dismiss() }
                        )
                    }) {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .tint(.white)
                        } else {
                            Text("Submit Counter-Offer")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(viewModel.isSubmitting || viewModel.isCancelling)
                    .listRowBackground(Color.blue)

                    Button(action: {
                        viewModel.cancelContractEntirely(onSuccess: { dismiss() })
                    }) {
                        if viewModel.isCancelling {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .tint(.red)
                        } else {
                            Text("Cancel Contract Entirely")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(viewModel.isSubmitting || viewModel.isCancelling)
                }
            }
            .navigationTitle("Dispute Contract")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                }
            }
            .onTapGesture { isInputFocused = false }
            .alert("Error", isPresented: Binding(
                get: { viewModel.submitError != nil },
                set: { if !$0 { viewModel.submitError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.submitError ?? "")
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.cancelError != nil },
                set: { if !$0 { viewModel.cancelError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.cancelError ?? "")
            }
        }
    }
}

#Preview {
    Text("Background Screen")
        .sheet(isPresented: .constant(true)) {
            DisputeModalView()
                .presentationDetents([.large, .medium])
        }
}
