// Location: New-Pol-Mure/Services/CalendarManager.swift

import Foundation
import UIKit
import EventKit
import CoreLocation
import Combine

class CalendarManager: ObservableObject {

    @Published var eventAddedSuccessfully = false
    @Published var permissionDenied       = false

    private let eventStore = EKEventStore()

   
    func addInspectionToCalendar(
        buyerName:        String,
        contractId:       String,
        amount:           Double,
        locationName:     String,
        sellerCoordinate: CLLocationCoordinate2D,
        date:             Date
    ) {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .authorized, .writeOnly:
            createBuyerArrivalEvent(buyerName: buyerName, contractId: contractId,
                                    amount: amount, locationName: locationName,
                                    sellerCoordinate: sellerCoordinate, date: date)

        case .notDetermined:
            eventStore.requestWriteOnlyAccessToEvents { [weak self] granted, _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if granted {
                        self.createBuyerArrivalEvent(buyerName: buyerName, contractId: contractId,
                                                     amount: amount, locationName: locationName,
                                                     sellerCoordinate: sellerCoordinate, date: date)
                    } else {
                        self.permissionDenied = true
                    }
                }
            }

        case .denied, .restricted:
            DispatchQueue.main.async { self.permissionDenied = true }
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }

        @unknown default:
            DispatchQueue.main.async { self.permissionDenied = true }
        }
    }

   
    private func createBuyerArrivalEvent(
        buyerName:        String,
        contractId:       String,
        amount:           Double,
        locationName:     String,
        sellerCoordinate: CLLocationCoordinate2D,
        date:             Date
    ) {
        let event = EKEvent(eventStore: eventStore)

        
        event.title = "Buyer Arriving: \(buyerName)"

        // Use EKStructuredLocation so Apple Maps shows the pin without exposing raw GPS coordinates
        let structuredLocation = EKStructuredLocation(title: locationName.isEmpty ? "Estate" : locationName)
        structuredLocation.geoLocation = CLLocation(latitude: sellerCoordinate.latitude, longitude: sellerCoordinate.longitude)
        event.structuredLocation = structuredLocation
        event.location = locationName.isEmpty ? nil : locationName

        // Notes: contract ref + value + deep link + preparation reminder
        event.notes = """
        Contract: \(contractId)
        Contract Value: Rs \(String(format: "%.2f", amount)) / nut
        Open in Polmure: polmure://contract/\(contractId)
        Prepare harvest: pile and grade coconuts before buyer arrives.
        """

       
        event.startDate = date
        event.endDate   = date.addingTimeInterval(7200)
        event.calendar  = eventStore.defaultCalendarForNewEvents

        
        let prepAlarm = EKAlarm()
        prepAlarm.relativeOffset = -86400
        event.addAlarm(prepAlarm)

      
        let readyAlarm = EKAlarm()
        readyAlarm.relativeOffset = -3600
        event.addAlarm(readyAlarm)

        do {
            try eventStore.save(event, span: .thisEvent)
            DispatchQueue.main.async { self.eventAddedSuccessfully = true }
        } catch {
            print("CalendarManager: failed to save event — \(error.localizedDescription)")
        }
    }
}
