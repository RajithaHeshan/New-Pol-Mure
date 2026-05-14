import CoreData
import Foundation
import FirebaseFirestore


final class CoreDataCache {
    static let shared = CoreDataCache()
    private let context: NSManagedObjectContext

    private init() {
        context = PersistenceController.shared.container.viewContext
    }

  
    func saveUserProfile(userId: String, data: [String: Any]) {
        context.perform {
            let request: NSFetchRequest<CachedUserProfile> = CachedUserProfile.fetchRequest()
            request.predicate = NSPredicate(format: "userId == %@", userId)
            let existing = (try? self.context.fetch(request))?.first ?? CachedUserProfile(context: self.context)

            existing.userId           = userId
            existing.fullName         = data["fullName"]         as? String ?? existing.fullName
            existing.role             = data["role"]             as? String ?? existing.role
            existing.locationName     = data["locationName"]     as? String ?? existing.locationName
            existing.profileImageName = data["profileImageName"] as? String ?? existing.profileImageName
            existing.typicalVolume    = data["typicalVolume"]    as? String ?? existing.typicalVolume
            existing.typicalYield     = data["typicalYield"]     as? String ?? existing.typicalYield
            existing.certificationLevel = data["certificationLevel"] as? String ?? existing.certificationLevel
            if let lat = data["latitude"]  as? Double { existing.latitude  = lat }
            if let lng = data["longitude"] as? Double { existing.longitude = lng }

            try? self.context.save()
        }
    }

    func loadUserProfile(userId: String) -> [String: Any]? {
        let request: NSFetchRequest<CachedUserProfile> = CachedUserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        guard let cached = (try? context.fetch(request))?.first else { return nil }
        return [
            "fullName":         cached.fullName         ?? "",
            "role":             cached.role             ?? "",
            "locationName":     cached.locationName     ?? "",
            "profileImageName": cached.profileImageName ?? "",
            "typicalVolume":    cached.typicalVolume    ?? "",
            "typicalYield":     cached.typicalYield     ?? "",
            "certificationLevel": cached.certificationLevel ?? "",
            "latitude":         cached.latitude,
            "longitude":        cached.longitude
        ]
    }

   

    func saveContracts(_ contracts: [Contract], ownerID: String) {
        context.perform {
            let delete: NSFetchRequest<CachedContract> = CachedContract.fetchRequest()
            delete.predicate = NSPredicate(format: "ownerID == %@", ownerID)
            (try? self.context.fetch(delete))?.forEach { self.context.delete($0) }

            for c in contracts {
                let cached           = CachedContract(context: self.context)
                cached.id            = c.id
                cached.contractRef   = c.contractRef
                cached.buyerID       = c.buyerID
                cached.buyerName     = c.buyerName
                cached.sellerID      = c.sellerID
                cached.sellerName    = c.sellerName
                cached.status        = c.status
                cached.amount        = c.amount
                cached.quantity      = Int32(c.quantity)
                cached.locationName  = c.locationName
                cached.createdAt     = c.createdAt
                cached.source        = c.source
                cached.ownerID       = ownerID
            }
            try? self.context.save()
        }
    }

    func loadContracts(ownerID: String) -> [Contract] {
        let request: NSFetchRequest<CachedContract> = CachedContract.fetchRequest()
        request.predicate = NSPredicate(format: "ownerID == %@", ownerID)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        let results = (try? context.fetch(request)) ?? []
        return results.compactMap { cached -> Contract? in
            guard
                let id          = cached.id,
                let contractRef = cached.contractRef,
                let buyerID     = cached.buyerID,
                let buyerName   = cached.buyerName,
                let sellerID    = cached.sellerID,
                let sellerName  = cached.sellerName,
                let status      = cached.status,
                let createdAt   = cached.createdAt
            else { return nil }
            return Contract(id: id, data: [
                "contractRef":  contractRef,
                "buyerID":      buyerID,
                "buyerName":    buyerName,
                "sellerID":     sellerID,
                "sellerName":   sellerName,
                "status":       status,
                "amount":       cached.amount,
                "quantity":     Int(cached.quantity),
                "locationName": cached.locationName ?? "",
                "createdAt":    Timestamp(date: createdAt),
                "source":       cached.source ?? "bid"
            ])
        }
    }



    func saveBids(_ bids: [Bid], ownerID: String) {
        context.perform {
            let delete: NSFetchRequest<CachedBid> = CachedBid.fetchRequest()
            delete.predicate = NSPredicate(format: "ownerID == %@", ownerID)
            (try? self.context.fetch(delete))?.forEach { self.context.delete($0) }

            for b in bids {
                let cached          = CachedBid(context: self.context)
                cached.id           = b.id
                cached.sellerID     = b.sellerID
                cached.sellerName   = b.sellerName
                cached.bidderID     = b.bidderID
                cached.bidderName   = b.bidderName
                cached.harvestID    = b.harvestID
                cached.amount       = b.amount
                cached.status       = b.status
                cached.wasAccepted  = b.wasAccepted
                cached.placedAt     = b.placedAt
                cached.ownerID      = ownerID
            }
            try? self.context.save()
        }
    }

    func loadBids(ownerID: String) -> [Bid] {
        let request: NSFetchRequest<CachedBid> = CachedBid.fetchRequest()
        request.predicate = NSPredicate(format: "ownerID == %@", ownerID)
        request.sortDescriptors = [NSSortDescriptor(key: "placedAt", ascending: false)]
        let results = (try? context.fetch(request)) ?? []
        return results.compactMap { cached -> Bid? in
            guard
                let id        = cached.id,
                let sellerID  = cached.sellerID,
                let bidderID  = cached.bidderID,
                let bidderName = cached.bidderName,
                let placedAt  = cached.placedAt
            else { return nil }
            return Bid(id: id, data: [
                "sellerID":    sellerID,
                "sellerName":  cached.sellerName ?? "",
                "bidderID":    bidderID,
                "bidderName":  bidderName,
                "harvestID":   cached.harvestID ?? "",
                "amount":      cached.amount,
                "status":      cached.status ?? "pending",
                "wasAccepted": cached.wasAccepted,
                "placedAt":    Timestamp(date: placedAt)
            ])
        }
    }

   

    func saveOffers(_ offers: [Offer], ownerID: String) {
        context.perform {
            let delete: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
            delete.predicate = NSPredicate(format: "ownerID == %@", ownerID)
            (try? self.context.fetch(delete))?.forEach { self.context.delete($0) }

            for o in offers {
                let cached            = CachedOffer(context: self.context)
                cached.id             = o.id
                cached.buyerID        = o.buyerID
                cached.buyerName      = o.buyerName
                cached.sellerID       = o.sellerID
                cached.sellerName     = o.sellerName
                cached.amount         = o.amount
                cached.status         = o.status
                cached.placedAt       = o.placedAt
                cached.isUrgentPitch  = o.isUrgentPitch
                cached.ownerID        = ownerID
            }
            try? self.context.save()
        }
    }

    func loadOffers(ownerID: String) -> [Offer] {
        let request: NSFetchRequest<CachedOffer> = CachedOffer.fetchRequest()
        request.predicate = NSPredicate(format: "ownerID == %@", ownerID)
        request.sortDescriptors = [NSSortDescriptor(key: "placedAt", ascending: false)]
        let results = (try? context.fetch(request)) ?? []
        return results.compactMap { cached -> Offer? in
            guard
                let id         = cached.id,
                let buyerID    = cached.buyerID,
                let sellerID   = cached.sellerID,
                let sellerName = cached.sellerName,
                let placedAt   = cached.placedAt
            else { return nil }
            return Offer(id: id, data: [
                "buyerID":       buyerID,
                "buyerName":     cached.buyerName ?? "",
                "sellerID":      sellerID,
                "sellerName":    sellerName,
                "amount":        cached.amount,
                "status":        cached.status ?? "pending",
                "placedAt":      Timestamp(date: placedAt),
                "isUrgentPitch": cached.isUrgentPitch
            ])
        }
    }

   

    func saveTransactions(_ transactions: [Transaction], ownerID: String) {
        context.perform {
            let delete: NSFetchRequest<CachedTransaction> = CachedTransaction.fetchRequest()
            delete.predicate = NSPredicate(format: "ownerID == %@", ownerID)
            (try? self.context.fetch(delete))?.forEach { self.context.delete($0) }

            for t in transactions {
                let cached             = CachedTransaction(context: self.context)
                cached.id              = t.id
                cached.contractRef     = t.contractRef
                cached.buyerID         = t.buyerID
                cached.buyerName       = t.buyerName
                cached.sellerID        = t.sellerID
                cached.sellerName      = t.sellerName
                cached.quantity        = Int32(t.quantity)
                cached.pricePerNut     = t.pricePerNut
                cached.amount          = t.amount
                cached.transactionFee  = t.transactionFee
                cached.locationName    = t.locationName
                cached.isCredit        = t.isCredit
                cached.completedAt     = t.completedAt
                cached.source          = t.source
                cached.ownerID         = ownerID
            }
            try? self.context.save()
        }
    }

    func loadTransactions(ownerID: String) -> [Transaction] {
        let request: NSFetchRequest<CachedTransaction> = CachedTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "ownerID == %@", ownerID)
        request.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]
        let results = (try? context.fetch(request)) ?? []
        return results.compactMap { cached -> Transaction? in
            guard
                let id          = cached.id,
                let buyerID     = cached.buyerID,
                let sellerID    = cached.sellerID,
                let completedAt = cached.completedAt
            else { return nil }
            return Transaction(id: id, data: [
                "contractRef":    cached.contractRef   ?? "",
                "buyerID":        buyerID,
                "buyerName":      cached.buyerName     ?? "",
                "sellerID":       sellerID,
                "sellerName":     cached.sellerName    ?? "",
                "quantity":       Int(cached.quantity),
                "pricePerNut":    cached.pricePerNut,
                "amount":         cached.amount,
                "transactionFee": cached.transactionFee,
                "locationName":   cached.locationName  ?? "",
                "isCredit":       cached.isCredit,
                "completedAt":    Timestamp(date: completedAt),
                "source":         cached.source        ?? "bid"
            ])
        }
    }
}
