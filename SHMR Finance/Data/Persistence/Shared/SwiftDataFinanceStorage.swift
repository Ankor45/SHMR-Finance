//
//  SwiftDataFinanceStorage.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataFinanceStorage: FinanceLocalStorage {
    init(
        isStoredInMemoryOnly: Bool = false,
        fileManager: FileManager = .default,
        storeFileName: String = LocalStorageScope.live.swiftDataStoreFileName
    ) throws {
        let configuration: ModelConfiguration

        if isStoredInMemoryOnly {
            configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        } else {
            let applicationSupportURL = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]
            try fileManager.createDirectory(
                at: applicationSupportURL,
                withIntermediateDirectories: true
            )
            configuration = ModelConfiguration(
                url: applicationSupportURL.appending(
                    path: storeFileName
                )
            )
        }

        let modelContainer = try ModelContainer(
            for: StoredTransaction.self,
            StoredPendingTransactionChange.self,
            StoredBankAccount.self,
            StoredPendingAccountChange.self,
            StoredCategory.self,
            configurations: configuration
        )
        let modelContext = ModelContext(modelContainer)

        self.modelContainer = modelContainer
        modelExecutor = DefaultSerialModelExecutor(
            modelContext: modelContext
        )
    }

    func repairPendingChanges() throws {
        var didRepair = false

        let transactionChanges = try modelContext.fetch(
            FetchDescriptor<StoredPendingTransactionChange>()
        )
        for storedChange in transactionChanges {
            do {
                _ = try decodePendingTransactionChange(storedChange)
            } catch {
                guard storedChange.state != .failed else {
                    continue
                }
                storedChange.stateRawValue = PendingChangeState.failed.rawValue
                storedChange.failureMessage = error.localizedDescription
                didRepair = true
            }
        }

        let accountChanges = try modelContext.fetch(
            FetchDescriptor<StoredPendingAccountChange>()
        )
        for storedChange in accountChanges {
            do {
                _ = try decodePendingAccountChange(storedChange)
            } catch {
                guard storedChange.state != .failed else {
                    continue
                }
                storedChange.stateRawValue = PendingChangeState.failed.rawValue
                storedChange.failureMessage = error.localizedDescription
                didRepair = true
            }
        }

        if didRepair {
            try saveChanges()
        }
    }

    func saveChanges() throws {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
