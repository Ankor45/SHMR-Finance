//
//  StoredPendingTransactionChange.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation
import SwiftData

@Model
nonisolated final class StoredPendingTransactionChange {
    @Attribute(.unique) var transactionId: Int
    var actionRawValue: String
    var payload: Data?
    var balanceAdjustmentPayload: Data
    var insertedAt: Date
    var revision: UUID
    var stateRawValue: String = "pending"
    var failureMessage: String?

    init(
        transactionId: Int,
        action: PendingTransactionAction,
        payload: Data?,
        balanceAdjustmentPayload: Data,
        insertedAt: Date = .now,
        revision: UUID = UUID()
    ) {
        self.transactionId = transactionId
        actionRawValue = action.rawValue
        self.payload = payload
        self.balanceAdjustmentPayload = balanceAdjustmentPayload
        self.insertedAt = insertedAt
        self.revision = revision
        stateRawValue = PendingChangeState.pending.rawValue
        failureMessage = nil
    }

    var action: PendingTransactionAction? {
        PendingTransactionAction(rawValue: actionRawValue)
    }

    var state: PendingChangeState? {
        PendingChangeState(rawValue: stateRawValue)
    }

    convenience init(snapshot: PendingTransactionStorageSnapshot) {
        self.init(
            transactionId: snapshot.transactionId,
            action: PendingTransactionAction(
                rawValue: snapshot.actionRawValue
            ) ?? .invalid,
            payload: snapshot.payload,
            balanceAdjustmentPayload: snapshot.balanceAdjustmentPayload,
            insertedAt: snapshot.insertedAt,
            revision: snapshot.revision
        )
        actionRawValue = snapshot.actionRawValue
        stateRawValue = snapshot.stateRawValue
        failureMessage = snapshot.failureMessage
    }
}
