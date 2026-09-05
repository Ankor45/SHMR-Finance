//
//  StoredPendingAccountChange.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation
import SwiftData

@Model
nonisolated final class StoredPendingAccountChange {
    @Attribute(.unique) var accountId: Int
    var payload: Data
    var insertedAt: Date
    var revision: UUID
    var stateRawValue: String = "pending"
    var failureMessage: String?

    init(
        accountId: Int,
        payload: Data,
        insertedAt: Date = .now,
        revision: UUID = UUID()
    ) {
        self.accountId = accountId
        self.payload = payload
        self.insertedAt = insertedAt
        self.revision = revision
        stateRawValue = PendingChangeState.pending.rawValue
        failureMessage = nil
    }

    var state: PendingChangeState? {
        PendingChangeState(rawValue: stateRawValue)
    }

    convenience init(snapshot: PendingAccountStorageSnapshot) {
        self.init(
            accountId: snapshot.accountId,
            payload: snapshot.payload,
            insertedAt: snapshot.insertedAt,
            revision: snapshot.revision
        )
        stateRawValue = snapshot.stateRawValue
        failureMessage = snapshot.failureMessage
    }
}
