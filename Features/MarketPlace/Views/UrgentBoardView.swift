
import SwiftUI

struct UrgentBoardView: View {
    @State private var viewModel = UrgentBoardViewModel()
    @State private var showCreateModal = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                        Text("Monitor your active urgent requests here.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    // MARK: Dynamic State Handling (Empty vs Populated)
                    if viewModel.isLoadingRequests {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                    } else if viewModel.myRequests.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "megaphone.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No Urgent Requests")
                                .font(.title3.bold())
                            Text("Need stock immediately? Post an urgent request and sellers will contact you.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)

                            Button(action: { showCreateModal = true }) {
                                Text("Post New Request")
                                    .font(.headline)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 10)
                        }
                        .padding(.vertical, 60)
                    } else {
                        ForEach(viewModel.myRequests) { request in
                            UrgentRequestCard(request: request) {
                                viewModel.deleteRequest(request)
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("My Urgent Needs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateModal = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showCreateModal) {
                UrgentRequestModalView(viewModel: viewModel)
                    .presentationDetents([.large])
            }
        }
    }
}

// MARK: - Subviews

struct UrgentRequestCard: View {
    let request: UrgentRequest
    let onDelete: () -> Void

    var urgencyColor: Color {
        let hoursLeft = request.deadline.timeIntervalSinceNow / 3600
        return hoursLeft < 6 ? .red : .orange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("YOUR POST")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(request.quantity) Nuts")
                        .font(.title2.bold())
                    Text(request.grade)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(urgencyColor)
                    Text(request.deadline, style: .relative)
                        .font(.caption.bold())
                        .foregroundColor(urgencyColor)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct UrgentRequestModalView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var viewModel: UrgentBoardViewModel

    @State private var quantity: Int = 1000
    @State private var selectedGrade: String = "Premium (Export Quality)"
    @State private var requiredDate: Date = Date().addingTimeInterval(86400) // Default: tomorrow

    let grades = ["Premium (Export Quality)", "Standard (Local Retail)", "Processing (Oil/Desiccated)", "Any Grade"]

    var dateRange: ClosedRange<Date> {
        let today = Date()
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        return today...nextWeek
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $quantity, in: 100...50000, step: 100) {
                        HStack {
                            Text("Quantity Required")
                            Spacer()
                            Text("\(quantity) Nuts")
                                .bold()
                                .foregroundColor(.blue)
                        }
                    }

                    Picker("Quality Grade", selection: $selectedGrade) {
                        ForEach(grades, id: \.self) { grade in
                            Text(grade).tag(grade)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("What do you need?")
                }

                Section {
                    DatePicker(
                        "Deadline",
                        selection: $requiredDate,
                        in: dateRange,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)

                } header: {
                    Text("When do you need it?")
                } footer: {
                    Text("Urgent requests must be fulfilled within the next 7 days.")
                }

                Section {
                    Button(action: {
                        viewModel.postUrgentRequest(quantity: quantity, grade: selectedGrade, deadline: requiredDate, onSuccess: { dismiss() })
                    }) {
                        if viewModel.isPosting {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("Post Urgent Request")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(viewModel.isPosting)
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("New Urgent Request")
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
    UrgentBoardView()
}
