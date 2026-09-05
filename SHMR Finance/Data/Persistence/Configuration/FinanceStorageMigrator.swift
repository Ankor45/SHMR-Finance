//
//  FinanceStorageMigrator.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation

nonisolated enum FinanceStorageMigrationError: LocalizedError, Sendable {
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            AppLocalization.string(
                localized: "Не удалось проверить перенос локальных данных"
            )
        }
    }
}

nonisolated struct FinanceStorageMigrator: Sendable {
    private let settings: LocalStorageSettings
    private let factory: LocalStorageFactory

    init(scope: LocalStorageScope = .live) {
        settings = LocalStorageSettings(scope: scope)
        factory = LocalStorageFactory(scope: scope)
    }

    @concurrent
    func prepareStorage() async throws -> any FinanceLocalStorage {
        let selectedKind = await settings.selectedStorage
        let activeKind = await settings.activeStorage
        let target = try factory.makeStorage(for: selectedKind)

        guard selectedKind != activeKind else {
            try await finishInterruptedCleanup(activeKind: activeKind)
            try await target.repairPendingChanges()
            return target
        }

        let source = try factory.makeStorage(for: activeKind)
        let snapshot = try await source.exportSnapshot()
        try await target.replaceContents(with: snapshot)

        let importedSnapshot = try await target.exportSnapshot()
        guard importedSnapshot.matchesContents(of: snapshot) else {
            throw FinanceStorageMigrationError.verificationFailed
        }

        await settings.activate(
            selectedKind,
            previousStorage: activeKind
        )
        try await source.removeAll()
        await settings.finishCleanup()
        try await target.repairPendingChanges()
        return target
    }

    private func finishInterruptedCleanup(
        activeKind: LocalStorageKind
    ) async throws {
        guard let cleanupKind = await settings.pendingCleanupStorage else {
            return
        }
        guard cleanupKind != activeKind else {
            await settings.finishCleanup()
            return
        }
        let storage = try factory.makeStorage(for: cleanupKind)
        try await storage.removeAll()
        await settings.finishCleanup()
    }
}

nonisolated private extension FinanceStorageSnapshot {
    func matchesContents(of other: FinanceStorageSnapshot) -> Bool {
        transactions.sorted { $0.id < $1.id }
            == other.transactions.sorted { $0.id < $1.id }
            && accounts.sorted { $0.id < $1.id }
                == other.accounts.sorted { $0.id < $1.id }
            && categories.sorted { $0.id < $1.id }
                == other.categories.sorted { $0.id < $1.id }
            && pendingTransactions.sorted {
                $0.transactionId < $1.transactionId
            } == other.pendingTransactions.sorted {
                $0.transactionId < $1.transactionId
            }
            && pendingAccounts.sorted {
                $0.accountId < $1.accountId
            } == other.pendingAccounts.sorted {
                $0.accountId < $1.accountId
            }
    }
}
