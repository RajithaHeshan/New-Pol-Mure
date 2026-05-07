

import Foundation
import UIKit
import EventKit
import CoreLocation
import UserNotifications
import Combine

class BuyerCalendarManager: ObservableObject {


    @Published var eventAddedSuccessfully = false
    @Published var permissionDenied       = false
    @Published var reminderDateExpired    = false  

    private let eventStore = EKEventStore()

  
    func addInspectionToCalendar(
        sellerName:       String,
        contractId:       String,
        amount:           Double,
        sellerYield:      String,
        locationName:     String,
        sellerCoordinate: CLLocationCoordinate2D,
        date:             Date,
        reminderOffset:   TimeInterval   
    ) {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .authorized, .writeOnly:
            createPickUpEvent(sellerName: sellerName, contractId: contractId,
                              amount: amount, sellerYield: sellerYield,
                              locationName: locationName, sellerCoordinate: sellerCoordinate,
                              date: date, reminderOffset: reminderOffset)

        case .notDetermined:
            eventStore.requestWriteOnlyAccessToEvents { [weak self] granted, _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if granted {
                        self.createPickUpEvent(sellerName: sellerName, contractId: contractId,
                                               amount: amount, sellerYield: sellerYield,
                                               locationName: locationName, sellerCoordinate: sellerCoordinate,
                                               date: date, reminderOffset: reminderOffset)
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

  
    private func createPickUpEvent(
        sellerName:       String,
        contractId:       String,
        amount:           Double,
        sellerYield:      String,
        locationName:     String,
        sellerCoordinate: CLLocationCoordinate2D,
        date:             Date,
        reminderOffset:   TimeInterval
    ) {
        let event = EKEvent(eventStore: eventStore)

    
        event.title = "Polmure Pick-up: \(sellerName)"

       
        let structuredLocation = EKStructuredLocation(title: locationName.isEmpty ? "Seller's Estate" : locationName)
        structuredLocation.geoLocation = CLLocation(latitude: sellerCoordinate.latitude, longitude: sellerCoordinate.longitude)
        event.structuredLocation = structuredLocation
        event.location = locationName.isEmpty ? nil : locationName

       
        let yieldLine = sellerYield.isEmpty ? "" : "Volume: \(sellerYield) Nuts\n"
        event.notes = """
        Contract: \(contractId)
        \(yieldLine)Contract Value: Rs \(String(format: "%.2f", amount)) / nut
        Open in Polmure: polmure://contract/\(contractId)
        """

       
        event.startDate = date
        event.endDate   = date.addingTimeInterval(7200)
        event.calendar  = eventStore.defaultCalendarForNewEvents

        let alarm = EKAlarm()
        alarm.relativeOffset = reminderOffset
        event.addAlarm(alarm)

        do {
            try eventStore.save(event, span: .thisEvent)
            DispatchQueue.main.async {
                self.eventAddedSuccessfully = true
               
                self.scheduleLocalNotification(sellerName: sellerName, locationName: locationName,
                                               contractId: contractId, date: date,
                                               reminderOffset: reminderOffset)
            }
        } catch {
            print("BuyerCalendarManager: failed to save event — \(error.localizedDescription)")
        }
    }


    private func scheduleLocalNotification(
        sellerName:     String,
        locationName:   String,
        contractId:     String,
        date:           Date,
        reminderOffset: TimeInterval
    ) {
        let fireDate     = date.addingTimeInterval(reminderOffset)
        let secondsUntil = fireDate.timeIntervalSinceNow

        print("📅 Scheduling pick-up reminder — inspectionDate: \(date), reminderOffset: \(reminderOffset)s, fireDate: \(fireDate), secondsUntil: \(secondsUntil)s")

        guard secondsUntil > 0 else {
            print("⚠️ Pick-up reminder skipped — fire date \(fireDate) is in the past (now: \(Date())).")
            DispatchQueue.main.async { self.reminderDateExpired = true }
            return
        }

        reminderDateExpired = false

        let content       = UNMutableNotificationContent()
        content.title     = "Time to Leave for Pick-up!"
        let locationLabel = locationName.isEmpty ? "the seller's estate" : locationName
        content.body      = "Your inspection at \(locationLabel) (\(sellerName)) is coming up. Contract \(contractId)."
        content.sound     = .default

        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: secondsUntil, repeats: false)
        let request = UNNotificationRequest(
            identifier: "pickup-reminder-\(contractId)",
            content:    content,
            trigger:    trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("❌ Pick-up notification error: \(error.localizedDescription)")
            } else {
                let formatter        = DateFormatter()
                formatter.dateStyle  = .short
                formatter.timeStyle  = .medium
                print("✅ Pick-up reminder registered — fires at \(formatter.string(from: fireDate)) (in \(Int(secondsUntil))s)")
            }
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
