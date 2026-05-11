import SwiftUI
import FirebaseFirestore

// MARK: - Rating Sheet (shown to both buyer and seller after transaction completes)

struct RatingSheet: View {
    let contractID:    String
    let reviewerID:    String
    let reviewerName:  String
    let revieweeID:    String
    let revieweeName:  String
    let role:          String   // "buyer" rating seller, or "seller" rating buyer

    @Environment(\.dismiss) private var dismiss

    @State private var selectedStars: Int = 0
    @State private var comment:       String = ""
    @State private var isSubmitting:  Bool = false
    @State private var submitted:     Bool = false

    private var themeColor: Color { role == "seller" ? .orange : .blue }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(themeColor)

                        Text("Rate Your Experience")
                            .font(.title2.bold())

                        Text("How was your transaction with **\(revieweeName)**?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    // Star picker
                    StarRatingPicker(selectedStars: $selectedStars, themeColor: themeColor)

                    // Star label
                    if selectedStars > 0 {
                        Text(starLabel(selectedStars))
                            .font(.subheadline.bold())
                            .foregroundColor(themeColor)
                            .transition(.opacity.combined(with: .scale))
                            .animation(.spring(response: 0.3), value: selectedStars)
                    }

                    // Comment box
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add a comment (optional)")
                            .font(.subheadline.bold())

                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                                .frame(minHeight: 100)

                            TextEditor(text: $comment)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.clear)
                                .scrollContentBackground(.hidden)

                            if comment.isEmpty {
                                Text("e.g. Great quality, punctual delivery…")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary.opacity(0.6))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    }
                    .padding(.horizontal)

                    // Submit button
                    Button(action: submit) {
                        if isSubmitting {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Submit Rating")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(selectedStars == 0 ? Color.secondary.opacity(0.3) : themeColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .disabled(selectedStars == 0 || isSubmitting)
                    .padding(.horizontal)

                    Button(action: { dismiss() }) {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 4)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Leave a Rating")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        // Success overlay
        .overlay {
            if submitted {
                SubmittedOverlay(revieweeName: revieweeName, themeColor: themeColor) {
                    dismiss()
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.spring(response: 0.4), value: submitted)
    }

    private func submit() {
        guard selectedStars > 0 else { return }
        isSubmitting = true

        let db = Firestore.firestore()
        let data: [String: Any] = [
            "contractID":   contractID,
            "reviewerID":   reviewerID,
            "reviewerName": reviewerName,
            "revieweeID":   revieweeID,
            "stars":        selectedStars,
            "comment":      comment,
            "createdAt":    Timestamp()
        ]

        Task {
            do {
                // Write rating document
                try await db.collection("ratings").addDocument(data: data)

                // Recompute and update the reviewee's average rating on their user profile
                let snapshot = try await db.collection("ratings")
                    .whereField("revieweeID", isEqualTo: revieweeID)
                    .getDocuments()

                let allStars = snapshot.documents.compactMap { $0.data()["stars"] as? Int }
                if !allStars.isEmpty {
                    let avg = Double(allStars.reduce(0, +)) / Double(allStars.count)
                    try? await db.collection("users").document(revieweeID)
                        .updateData(["averageRating": avg, "ratingCount": allStars.count])
                }

                isSubmitting = false
                submitted = true
            } catch {
                print("Rating submit error: \(error.localizedDescription)")
                isSubmitting = false
            }
        }
    }

    private func starLabel(_ stars: Int) -> String {
        switch stars {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent"
        default: return ""
        }
    }
}

// MARK: - Star Rating Picker

struct StarRatingPicker: View {
    @Binding var selectedStars: Int
    var themeColor: Color = .orange

    var body: some View {
        HStack(spacing: 12) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= selectedStars ? "star.fill" : "star")
                    .font(.system(size: 40))
                    .foregroundColor(star <= selectedStars ? themeColor : Color.secondary.opacity(0.35))
                    .scaleEffect(star <= selectedStars ? 1.1 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: selectedStars)
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        selectedStars = star
                    }
            }
        }
    }
}

// MARK: - Success Overlay

private struct SubmittedOverlay: View {
    let revieweeName: String
    let themeColor:   Color
    let onDone:       () -> Void

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(themeColor)

                Text("Rating Submitted!")
                    .font(.title2.bold())

                Text("Your feedback for **\(revieweeName)** has been saved.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: onDone) {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
        }
    }
}
