//
//  CoreDataFinanceStorage.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

@preconcurrency import CoreData
import Foundation

nonisolated final class CoreDataFinanceStorage:
    FinanceLocalStorage,
    @unchecked Sendable {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    init(
        isStoredInMemoryOnly: Bool = false,
        fileManager: FileManager = .default,
        storeFileName: String = LocalStorageScope.live.coreDataStoreFileName
    ) throws {
        container = NSPersistentContainer(
            name: FinanceCoreDataModel.name,
            managedObjectModel: FinanceCoreDataModel.make()
        )

        let description = NSPersistentStoreDescription()
        if isStoredInMemoryOnly {
            description.type = NSInMemoryStoreType
        } else {
            let applicationSupportURL = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]
            try fileManager.createDirectory(
                at: applicationSupportURL,
                withIntermediateDirectories: true
            )
            description.url = applicationSupportURL.appending(
                path: storeFileName
            )
        }
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]

        var loadingError: Error?
        container.loadPersistentStores { _, error in
            loadingError = error
        }
        if let loadingError {
            throw loadingError
        }

        context = container.newBackgroundContext()
        context.name = "FinanceCoreDataStorage"
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func perform<T: Sendable>(
        _ operation: @escaping @Sendable (CoreDataStorageSession) throws -> T
    ) async throws -> T {
        let context = self.context
        return try await context.perform {
            let session = CoreDataStorageSession(context: context)
            do {
                let result = try operation(session)
                if context.hasChanges {
                    try context.save()
                }
                return result
            } catch {
                context.rollback()
                throw error
            }
        }
    }
}
