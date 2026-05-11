

import Foundation

enum SellerContractState: Int, CaseIterable {
    case escrowSecured = 0
    case buyerEnRoute = 1
    case qualityApproved = 2
    case completed = 3
}

