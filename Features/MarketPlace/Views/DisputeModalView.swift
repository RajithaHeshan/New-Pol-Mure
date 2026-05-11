

import SwiftUI

struct DisputeModalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var viewModel: DisputeModalViewModel
    @FocusState private var isInputFocused: Bool

    
    @State private var selectedReason: String = "Quality (Rotten/Spoiled)"
    @State private var additionalNotes: String = ""
    @State private var counterOfferAmount: String = ""
    @State private var localError: String? = nil

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
                        //print("🔵 Submit button tapped — counterOfferAmount: '\(counterOfferAmount)'")
                        let amount = counterOfferAmount.trimmingCharacters(in: .whitespaces)
                        guard !amount.isEmpty, let value = Double(amount), value > 0 else {
                            print("🔵 View guard failed — amount: '\(amount)'")
                            localError = "Enter a counter-offer amount greater than 0."
                            return
                        }
                        viewModel.submitCounterOffer(
                            reason: selectedReason,
                            notes: additionalNotes,
                            counterOffer: amount,
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
                }

               
                Section {
                    Button(role: .destructive, action: {
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
                        }
                    }
                    .disabled(viewModel.isSubmitting || viewModel.isCancelling)
                } footer: {
                    Text("This permanently cancels the contract and releases the escrow. This action cannot be undone.")
                        .foregroundColor(.secondary)
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
            .alert("Error", isPresented: Binding(
                get: { localError != nil || viewModel.submitError != nil || viewModel.cancelError != nil },
                set: { if !$0 { localError = nil; viewModel.submitError = nil; viewModel.cancelError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(localError ?? viewModel.submitError ?? viewModel.cancelError ?? "")
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
