//
//  SynchronizationStatusStore.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation
import Observation

nonisolated struct SynchronizationIssue: Identifiable, Equatable, Sendable {
    let id: String
    let message: String
}

@MainActor
protocol SynchronizationStatusReporting: Sendable {
    func update(issues: [SynchronizationIssue])
}

nonisolated protocol FinanceSynchronizing: Sendable {
    func synchronize() async throws
}

@MainActor
@Observable
final class SynchronizationStatusStore: SynchronizationStatusReporting {
    private(set) var issues: [SynchronizationIssue] = []
    private(set) var isDismissed = false

    func update(issues: [SynchronizationIssue]) {
        if self.issues != issues {
            isDismissed = false
        }
        self.issues = issues
    }

    func dismiss() {
        isDismissed = true
    }
}
