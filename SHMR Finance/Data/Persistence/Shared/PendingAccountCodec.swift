//
//  PendingAccountCodec.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation

nonisolated enum PendingAccountCodec {
    static func decodeChange(
        accountId: Int,
        payload: Data,
        revision: UUID,
        stateRawValue: String,
        failureMessage: String?
    ) throws -> PendingAccountChange {
        guard let state = PendingChangeState(rawValue: stateRawValue) else {
            throw FinanceStorageError.invalidPendingAccount(id: accountId)
        }

        let account: BankAccount?
        if state == .failed {
            account = try? decode(from: payload, accountId: accountId)
        } else {
            account = try decode(from: payload, accountId: accountId)
        }

        return PendingAccountChange(
            accountId: accountId,
            account: account,
            revision: revision,
            state: state,
            errorMessage: failureMessage
        )
    }

    static func encode(_ account: BankAccount) throws -> Data {
        try JSONEncoder().encode(account)
    }

    static func decode(
        from data: Data,
        accountId: Int
    ) throws -> BankAccount {
        do {
            return try JSONDecoder().decode(BankAccount.self, from: data)
        } catch {
            throw FinanceStorageError.invalidPendingAccount(id: accountId)
        }
    }
}
