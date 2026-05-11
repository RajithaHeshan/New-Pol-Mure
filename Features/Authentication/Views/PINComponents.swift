import SwiftUI

// MARK: - PIN Dots
struct PINDotsView: View {
    let count: Int
    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index < count ? Color.polmureEmerald : Color.clear)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color.polmureEmerald, lineWidth: 2))
                    .animation(.spring(duration: 0.2), value: count)
            }
        }
    }
}

// MARK: - PIN Pad
struct PINPadView: View {
    let onDigit: (String) -> Void
    let onDelete: () -> Void

    private let rows = [["1","2","3"],["4","5","6"],["7","8","9"]]

    var body: some View {
        VStack(spacing: 16) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 24) {
                    ForEach(row, id: \.self) { digit in
                        PINKeyButton(label: digit) { onDigit(digit) }
                    }
                }
            }
            HStack(spacing: 24) {
                Color.clear.frame(width: 80, height: 80)
                PINKeyButton(label: "0") { onDigit("0") }
                Button(action: onDelete) {
                    Image(systemName: "delete.left")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 80, height: 80)
                }
            }
        }
        .padding(.horizontal, 32)
    }
}

struct PINKeyButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 28, weight: .regular, design: .rounded))
                .foregroundColor(.primary)
                .frame(width: 80, height: 80)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(Circle())
        }
    }
}

// MARK: - Shake animation modifier
struct ShakeModifier: AnimatableModifier {
    var shake: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: shake ? 8 : 0)
            .animation(
                shake
                    ? Animation.easeInOut(duration: 0.07).repeatCount(4, autoreverses: true)
                    : .default,
                value: shake
            )
    }
}
