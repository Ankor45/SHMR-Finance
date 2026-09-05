//
//  PendingTransactionCodec.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation

nonisolated enum PendingTransactionCodec {
    static func decodeChange(
        transactionId: Int,
        actionRawValue: String,
        payload: Data?,
        balanceAdjustmentPayload: Data,
        revision: UUID,
        stateRawValue: String,
        failureMessage: String?
    ) throws -> PendingTransactionChange {
        guard let state = PendingChangeState(rawValue: stateRawValue) else {
            throw FinanceStorageError.invalidPendingTransaction(
                id: transactionId
            )
        }
        let action = PendingTransactionAction(rawValue: actionRawValue)
            ?? .invalid

        if state == .failed {
            return PendingTransactionChange(
                transactionId: transactionId,
                action: action,
                transaction: payload.flatMap {
                    try? decodeTransaction(
                        from: $0,
                        transactionId: transactionId
                    )
                },
                balanceAdjustment: (
                    try? decodeBalanceAdjustment(
                        from: balanceAdjustmentPayload,
                        transactionId: transactionId
                    )
                ) ?? [:],
                revision: revision,
                state: state,
                errorMessage: failureMessage
            )
        }

        guard action != .invalid else {
            throw FinanceStorageError.invalidPendingTransaction(
                id: transactionId
            )
        }

        let transaction: Transaction?
        switch action {
        case .create, .update:
            guard let payload else {
                throw FinanceStorageError.invalidPendingTransaction(
                    id: transactionId
                )
            }
            transaction = try decodeTransaction(
                from: payload,
                transactionId: transactionId
            )
        case .delete, .invalid:
            transaction = nil
        }

        return PendingTransactionChange(
            transactionId: transactionId,
            action: action,
            transaction: transaction,
            balanceAdjustment: try decodeBalanceAdjustment(
                from: balanceAdjustmentPayload,
                transactionId: transactionId
            ),
            revision: revision,
            state: state,
            errorMessage: failureMessage
        )
    }

    static func encodeTransaction(_ transaction: Transaction) throws -> Data {
        try JSONEncoder().encode(TransactionSnapshot(transaction: transaction))
    }

    static func decodeTransaction(
        from data: Data,
        transactionId: Int
    ) throws -> Transaction {
        do {
            return try JSONDecoder()
                .decode(TransactionSnapshot.self, from: data)
                .toDomain()
        } catch {
            throw FinanceStorageError.invalidPendingTransaction(
                id: transactionId
            )
        }
    }

    static func encodeBalanceAdjustment(
        _ adjustment: [Int: Decimal]
    ) throws -> Data {
        let snapshots = adjustment.map {
            AccountBalanceDeltaSnapshot(
                accountId: $0.key,
                amount: PersistenceDecimalCodec.string(from: $0.value)
            )
        }
        return try JSONEncoder().encode(snapshots)
    }

    static func decodeBalanceAdjustment(
        from data: Data,
        transactionId: Int
    ) throws -> [Int: Decimal] {
        do {
            let snapshots = try JSONDecoder().decode(
                [AccountBalanceDeltaSnapshot].self,
                from: data
            )
            var result: [Int: Decimal] = [:]

            for snapshot in snapshots {
                guard let amount = PersistenceDecimalCodec.decimal(
                    from: snapshot.amount
                ) else {
                    throw FinanceStorageError.invalidPendingTransaction(
                        id: transactionId
                    )
                }
                result[snapshot.accountId, default: .zero] += amount
            }
            return result
        } catch let error as FinanceStorageError {
            throw error
        } catch {
            throw FinanceStorageError.invalidPendingTransaction(
                id: transactionId
            )
        }
    }

    static func mergeBalanceAdjustment(
        from storedPayload: Data,
        with adjustment: [Int: Decimal],
        transactionId: Int
    ) throws -> Data {
        var result = try decodeBalanceAdjustment(
            from: storedPayload,
            transactionId: transactionId
        )
        for (accountID, amount) in adjustment {
            result[accountID, default: .zero] += amount
            if result[accountID] == .zero {
                result[accountID] = nil
            }
        }
        return try encodeBalanceAdjustment(result)
    }
}
