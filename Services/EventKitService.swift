// Location: New-Pol-Mure/Services/EventKitService.swift

import Foundation
import UIKit
import EventKit
import CoreLocation
import UserNotifications
import Combine

class BuyerCalendarManager: ObservableObject {

    // MARK: - Published State
    @Published var eventAddedSuccessfully = false
    @Published var permissionDenied       = false
    @Published var reminderDateExpired    = false   // true when chosen reminder time is already past

    private let eventStore = EKEventStore()

    // MARK: - Public Entry Point
    func addInspectionToCalendar(
        sellerName:       String,
        contractId:       String,
        amount:           Double,
        sellerYield:      String,
        locationName:     String,
        sellerCoordinate: CLLocationCoordinate2D,
        date:             Date,
        reminderOffset:   TimeInterval   // negative seconds before event e.g. -3600 = 1 h before
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

    // MARK: - Private Event Builder
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

        // Title: "Polmure Pick-up: Mahesh Silva"
        event.title = "Polmure Pick-up: \(sellerName)"

        // Use EKStructuredLocation so Apple Maps shows the pin and computes travel time
        // without exposing raw GPS coordinates to the user
        let structuredLocation = EKStructuredLocation(title: locationName.isEmpty ? "Seller's Estate" : locationName)
        structuredLocation.geoLocation = CLLocation(latitude: sellerCoordinate.latitude, longitude: sellerCoordinate.longitude)
        event.structuredLocation = structuredLocation
        event.location = locationName.isEmpty ? nil : locationName

        // Notes: contract ref + volume + Rs/nut + deep link
        let yieldLine = sellerYield.isEmpty ? "" : "Volume: \(sellerYield) Nuts\n"
        event.notes = """
        Contract: \(contractId)
        \(yieldLine)Contract Value: Rs \(String(format: "%.2f", amount)) / nut
        Open in Polmure: polmure://contract/\(contractId)
        """

        // Timing — 2-hour window for inspection + handover
        event.startDate = date
        event.endDate   = date.addingTimeInterval(7200)
        event.calendar  = eventStore.defaultCalendarForNewEvents

        // EKAlarm — fires at buyer's chosen offset before the event
        let alarm = EKAlarm()
        alarm.relativeOffset = reminderOffset
        event.addAlarm(alarm)

        do {
            try eventStore.save(event, span: .thisEvent)
            DispatchQueue.main.async {
                self.eventAddedSuccessfully = true
                // Schedule UNNotification on main thread after calendar save succeeds
                self.scheduleLocalNotification(sellerName: sellerName, locationName: locationName,
                                               contractId: contractId, date: date,
                                               reminderOffset: reminderOffset)
            }
        } catch {
            print("BuyerCalendarManager: failed to save event — \(error.localizedDescription)")
        }
    }

    // MARK: - Local Push Notification (fires at reminderOffset before inspection)
    // Must be called on the main thread.
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

        // UNTimeIntervalNotificationTrigger fires in exactly secondsUntil seconds —
        // precise to the second, unlike UNCalendarNotificationTrigger (minute precision only).
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
