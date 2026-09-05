//
//  BalanceAdjustmentRoute.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import Foundation

struct BalanceAdjustmentRoute: Identifiable {
    let account: BankAccount
    let onConfirm: (Decimal) async throws -> Void

    var id: Int {
        account.id
    }
}
