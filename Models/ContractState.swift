
import Foundation

enum ContractState: Int, CaseIterable {
    case bidAccepted = 0
    case fundsLocked = 1
    case inspectionPending = 2
    case paymentPending = 3
    case completed = 4
}
