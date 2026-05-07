import SwiftUI

struct NotificationsView: View {
    let ownerID: String
    let accentColor: Color
    let onDismiss: () -> Void

    @State private var store = NotificationStore.shared

    var body: some View {
        NavigationStack {
            Group {
                if store.notifications.isEmpty {
                    emptyState
                } else {
                    notificationList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { onDismiss() }
                        .foregroundColor(accentColor)
                }
                if !store.notifications.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                store.markAllRead(ownerID: ownerID)
                            } label: {
                                Label("Mark All as Read", systemImage: "checkmark.circle")
                            }
                            Button(role: .destructive) {
                                store.deleteAll(ownerID: ownerID)
                            } label: {
                                Label("Clear All", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(accentColor)
                        }
                    }
                }
            }
        }
        .onAppear {
            store.load(ownerID: ownerID)
            store.markAllRead(ownerID: ownerID)
        }
    }

    // MARK: - List
    private var notificationList: some View {
        List {
            ForEach(store.notifications) { notification in
                NotificationRow(notification: notification, accentColor: accentColor)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            store.delete(id: notification.id, ownerID: ownerID)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .background(Color(UIColor.systemGroupedBackground))
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 52))
                .foregroundColor(.secondary.opacity(0.4))
            Text("No Notifications")
                .font(.title3.bold())
            Text("You'll see alerts here when you receive bids, pitches, or market updates.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Row
struct NotificationRow: View {
    let notification: AppNotification
    let accentColor: Color

    private var icon: String {
        switch notification.type {
        case "bid":        return "hammer.fill"
        case "offer":      return "hand.raised.fill"
        case "outbid":     return "arrow.up.circle.fill"
        case "outpitched": return "arrow.up.circle.fill"
        case "contract":   return "doc.text.fill"
        default:           return "bell.fill"
        }
    }

    private var iconColor: Color {
        switch notification.type {
        case "bid", "offer":           return accentColor
        case "outbid", "outpitched":   return .orange
        case "contract":               return .green
        default:                       return .secondary
        }
    }

    private var timeString: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: notification.receivedAt, relativeTo: Date())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon badge
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Spacer()
                    Text(timeString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text(notification.body)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Unread dot
            if !notification.isRead {
                Circle()
                    .fill(accentColor)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}
