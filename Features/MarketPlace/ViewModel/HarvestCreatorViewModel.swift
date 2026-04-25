import SwiftUI
import MapKit
import FirebaseFirestore

private final class HarvestListenerBox {
    var listener: ListenerRegistration?
    init() {}
    deinit { listener?.remove() }
}

@Observable
@MainActor
class HarvestCreatorViewModel {

    // MARK: - My Harvest Lots
    var myHarvests: [HarvestLotItem] = []
    var isLoadingHarvests = false

    // MARK: - Create Form Inputs
    var propertyName: String = ""
    var quantity: String = ""
    var qualityGrade: String = "Premium (Export Quality)"
    var harvestDate: Date = Date()
    var startingPrice: String = ""

    let qualityOptions = [
        "Premium (Export Quality)",
        "Standard (Local Market)",
        "Processing/Oil Grade",
        "Mixed Harvest"
    ]

    // MARK: - Location
    var estateLocation = CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609)
    var locationName: String = ""
    var isFullScreenMapPresented = false
    var inlineCameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609),
        latitudinalMeters: 5000,
        longitudinalMeters: 5000
    ))
    var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 7.4818, longitude: 80.3609),
        latitudinalMeters: 15000,
        longitudinalMeters: 15000
    ))

    // MARK: - Posting State
    var isLaunching  = false
    var launchError: String? = nil
    var launchSuccess = false

    private var currentSellerID:   String = ""
    private var currentSellerName: String = ""
    private var sellerLocationName: String = ""

    private let harvestsListenerBox = HarvestListenerBox()

    init() {
        self.currentSellerID = AuthManager.shared.currentUserID
        fetchSellerProfile()
        attachHarvestsListener()
    }

    // MARK: - Fetch Seller Profile
    private func fetchSellerProfile() {
        guard !currentSellerID.isEmpty else { return }
        Task {
            let doc = try? await Firestore.firestore()
                .collection("users")
                .document(currentSellerID)
                .getDocument()
            guard let data = doc?.data() else { return }

            currentSellerName  = data["fullName"]     as? String ?? ""
            sellerLocationName = data["locationName"] as? String ?? ""
            locationName       = sellerLocationName

            if let lat = data["latitude"] as? Double,
               let lng = data["longitude"] as? Double {
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                estateLocation = coord
                inlineCameraPosition = .region(MKCoordinateRegion(
                    center: coord,
                    latitudinalMeters: 5000,
                    longitudinalMeters: 5000
                ))
                cameraPosition = .region(MKCoordinateRegion(
                    center: coord,
                    latitudinalMeters: 15000,
                    longitudinalMeters: 15000
                ))
            }
        }
    }

    // MARK: - Live Harvests Listener
    private func attachHarvestsListener() {
        guard !currentSellerID.isEmpty else { return }
        isLoadingHarvests = true

        harvestsListenerBox.listener = Firestore.firestore()
            .collection("harvestLots")
            .whereField("sellerID", isEqualTo: currentSellerID)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("Harvests listener error: \(error.localizedDescription)")
                    self.isLoadingHarvests = false
                    return
                }
                self.myHarvests = snapshot?.documents.compactMap {
                    HarvestLotItem(id: $0.documentID, data: $0.data())
                }.sorted { $0.createdAt > $1.createdAt } ?? []
                self.isLoadingHarvests = false
            }
    }

    // MARK: - Delete Harvest
    func deleteHarvest(_ harvest: HarvestLotItem) {
        Firestore.firestore().collection("harvestLots").document(harvest.id).delete { error in
            if let error { print("Delete harvest error: \(error.localizedDescription)") }
        }
    }

    // MARK: - Price Suggestion
    var suggestedPrice: Double {
        switch qualityGrade {
        case "Premium (Export Quality)": return 110.00
        case "Standard (Local Market)":  return 95.00
        case "Processing/Oil Grade":     return 75.00
        default:                         return 85.00
        }
    }

    var marketAverage: Double { suggestedPrice + 5.0 }

    var isReadyForSuggestion: Bool {
        guard !quantity.isEmpty, let qty = Int(quantity) else { return false }
        return qty > 0
    }

    func applySuggestion() {
        startingPrice = String(format: "%.2f", suggestedPrice)
    }

    // MARK: - Launch Auction
    func launchAuction(onSuccess: @escaping @MainActor () -> Void = {}) {
        guard
            let qty = Int(quantity), qty > 0,
            let price = Double(startingPrice), price > 0,
            !currentSellerID.isEmpty
        else { return }

        isLaunching   = true
        launchError   = nil
        launchSuccess = false

        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

        let data: [String: Any] = [
            "sellerID":      currentSellerID,
            "sellerName":    currentSellerName,
            "propertyName":  propertyName,
            "locationName":  locationName.isEmpty ? sellerLocationName : locationName,
            "latitude":      estateLocation.latitude,
            "longitude":     estateLocation.longitude,
            "quantity":      qty,
            "qualityGrade":  qualityGrade,
            "harvestDate":   Timestamp(date: harvestDate),
            "startingPrice": price,
            "currentBid":    price,
            "endDate":       Timestamp(date: endDate),
            "createdAt":     Timestamp()
        ]

        Task {
            do {
                try await Firestore.firestore()
                    .collection("harvestLots")
                    .addDocument(data: data)
                propertyName  = ""
                quantity      = ""
                startingPrice = ""
                harvestDate   = Date()
                launchSuccess = true
                await onSuccess()
            } catch {
                print("Launch auction error: \(error.localizedDescription)")
                launchError = error.localizedDescription
            }
            isLaunching = false
        }
    }
}

// MARK: - HarvestLotItem model (for this seller's own listings)
struct HarvestLotItem: Identifiable {
    let id: String
    let sellerID: String
    let propertyName: String
    let sellerName: String
    let quantity: Int
    let qualityGrade: String
    let startingPrice: Double
    let currentBid: Double
    let locationName: String
    let latitude: Double
    let longitude: Double
    let endDate: Date
    let createdAt: Date

    init?(id: String, data: [String: Any]) {
        guard
            let quantity      = data["quantity"]      as? Int,
            let qualityGrade  = data["qualityGrade"]  as? String,
            let startingPrice = data["startingPrice"] as? Double,
            let endDate       = (data["endDate"]      as? Timestamp)?.dateValue(),
            let createdAt     = (data["createdAt"]    as? Timestamp)?.dateValue()
        else { return nil }

        self.id            = id
        self.sellerID      = data["sellerID"]      as? String ?? ""
        self.propertyName  = data["propertyName"]  as? String ?? ""
        self.sellerName    = data["sellerName"]    as? String ?? ""
        self.quantity      = quantity
        self.qualityGrade  = qualityGrade
        self.startingPrice = startingPrice
        self.currentBid    = data["currentBid"]    as? Double ?? startingPrice
        self.locationName  = data["locationName"]  as? String ?? ""
        self.latitude      = data["latitude"]      as? Double ?? 7.4818
        self.longitude     = data["longitude"]     as? Double ?? 80.3609
        self.endDate       = endDate
        self.createdAt     = createdAt
    }

    func toHarvestLot() -> HarvestLot {
        HarvestLot(
            id: id,
            sellerID: sellerID,
            sellerInitial: sellerName,
            propertyName: propertyName,
            locationName: locationName,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            quantity: quantity,
            qualityGrade: qualityGrade,
            currentBid: currentBid,
            endDate: endDate
        )
    }
}
