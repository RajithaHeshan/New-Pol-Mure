

import SwiftUI
import MapKit

@Observable
@MainActor
class LiveOfferViewModel {
    let buyer: RegisteredBuyer
    
    var userOfferInput: String = ""
    var currentLowestOffer: Double
    var isUnderbid: Bool = false
    
    init(buyer: RegisteredBuyer, currentMarketPrice: Double = 120.0) {
        self.buyer = buyer
        self.currentLowestOffer = currentMarketPrice
    }
    
 
    func incrementOffer(by amount: Double) {
        let currentInput = Double(userOfferInput) ?? currentLowestOffer
        userOfferInput = String(format: "%.0f", currentInput + amount)
    }
    
    func decrementOffer() {
        let currentInput = Double(userOfferInput) ?? currentLowestOffer
        if currentInput > 1 {
            userOfferInput = String(format: "%.0f", currentInput - 1)
        }
    }
    
    func decrementOffer(bySpecificAmount amount: Double) {
        let currentInput = Double(userOfferInput) ?? currentLowestOffer
        if currentInput > amount {
            userOfferInput = String(format: "%.0f", currentInput - amount)
        }
    }
    
    func sendPitch() -> Bool {
        if let newOffer = Double(userOfferInput), newOffer > 0 {
            // In a real app, this sends the pitch to the server.
            if newOffer < currentLowestOffer {
                currentLowestOffer = newOffer
            }
            userOfferInput = ""
            isUnderbid = false
            return true
        }
        return false
    }
    
 
    func simulateCheaperOffer() {
        currentLowestOffer -= 5.0
        isUnderbid = true
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}
