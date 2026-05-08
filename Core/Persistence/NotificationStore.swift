import Foundation
import CoreData
import SwiftUI

// MARK: - Model
struct AppNotification: Identifiable {
    let id:         String
    let ownerID:    String
    let title:      String
    let body:       String
    let type:       String
    var isRead:     Bool
    let receivedAt: Date
}

// MARK: - Store
@Observable
@MainActor
final class NotificationStore {
    static let shared = NotificationStore()

    private(set) var notifications: [AppNotification] = []

    private let context = PersistenceController.shared.container.viewContext

    private init() {}

    // MARK: - Load
    func load(ownerID: String) {
        let request: NSFetchRequest<CachedNotification> = CachedNotification.fetchRequest()
        request.predicate = NSPredicate(format: "ownerID == %@", ownerID)
        request.sortDescriptors = [NSSortDescriptor(key: "receivedAt", ascending: false)]
        let results = (try? context.fetch(request)) ?? []
        notifications = results.compactMap { cached in
            guard
                let id         = cached.id,
                let title      = cached.title,
                let body       = cached.body,
                let type       = cached.type,
                let receivedAt = cached.receivedAt
            else { return nil }
            return AppNotification(
                id:         id,
                ownerID:    cached.ownerID ?? ownerID,
                title:      title,
                body:       body,
                type:       type,
                isRead:     cached.isRead,
                receivedAt: receivedAt
            )
        }
    }

    // MARK: - Save new notification
    func add(ownerID: String, title: String, body: String, type: String) {
        let n = CachedNotification(context: context)
        n.id         = UUID().uuidString
        n.ownerID    = ownerID
        n.title      = title
        n.body       = body
        n.type       = type
        n.isRead     = false
        n.receivedAt = Date()
        try? context.save()
        load(ownerID: ownerID)
    }

    // MARK: - Mark all read
    func markAllRead(ownerID: String) {
        let request: NSFetchRequest<CachedNotification> = CachedNotification.fetchRequest()
        request.predicate = NSPredicate(format: "ownerID == %@ AND isRead == NO", ownerID)
        let unread = (try? context.fetch(request)) ?? []
        unread.forEach { $0.isRead = true }
        try? context.save()
        load(ownerID: ownerID)
    }

    // MARK: - Delete single
    func delete(id: String, ownerID: String) {
        let request: NSFetchRequest<CachedNotification> = CachedNotification.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        (try? context.fetch(request))?.forEach { context.delete($0) }
        try? context.save()
        load(ownerID: ownerID)
    }

    // MARK: - Delete all
    func deleteAll(ownerID: String) {
        let request: NSFetchRequest<CachedNotification> = CachedNotification.fetchRequest()
        request.predicate = NSPredicate(format: "ownerID == %@", ownerID)
        (try? context.fetch(request))?.forEach { context.delete($0) }
        try? context.save()
        load(ownerID: ownerID)
    }

    // MARK: - Unread count
    func unreadCount(ownerID: String) -> Int {
        notifications.filter { $0.ownerID == ownerID && !$0.isRead }.count
    }
}
