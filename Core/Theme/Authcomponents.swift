
import SwiftUI

// 1. Centralize your brand color so it can be used anywhere in the app
extension Color {
    static let polmureEmerald = Color(red: 0.1, green: 0.5, blue: 0.3)
}

// 2. Reusable Logo Component
struct PolmureHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [Color.polmureEmerald, .green], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.polmureEmerald.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            .padding(.top, 40)
            
            VStack(spacing: 4) {
                Text("Polmure")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .tracking(-1)
                
                Text("The Smart Coconut Marketplace")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// 3. Reusable Primary Button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.polmureEmerald)
                .cornerRadius(14)
                .shadow(color: Color.polmureEmerald.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

