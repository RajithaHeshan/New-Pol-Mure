// Location: New-Pol-Mure/Models/ContractState.swift

import Foundation

enum ContractState: Int, CaseIterable {
    case bidAccepted = 0
    case inspectionPending = 1
    case paymentPending = 2
    case completed = 3
}
