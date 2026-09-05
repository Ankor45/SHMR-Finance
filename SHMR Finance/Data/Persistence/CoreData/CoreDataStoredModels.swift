//
//  CoreDataStoredModels.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

@preconcurrency import CoreData
import Foundation

nonisolated final class CoreDataStoredTransaction: NSManagedObject {
    static let entityName = "StoredTransaction"

    @NSManaged var transactionId: Int64
    @NSManaged var accountId: Int64
    @NSManaged var payload: Data
    @NSManaged var transactionDate: Date
}

nonisolated final class CoreDataStoredAccount: NSManagedObject {
    static let entityName = "StoredAccount"

    @NSManaged var accountId: Int64
    @NSManaged var payload: Data
}

nonisolated final class CoreDataStoredCategory: NSManagedObject {
    static let entityName = "StoredCategory"

    @NSManaged var categoryId: Int64
    @NSManaged var payload: Data
}

nonisolated final class CoreDataPendingTransaction: NSManagedObject {
    static let entityName = "PendingTransaction"

    @NSManaged var transactionId: Int64
    @NSManaged var actionRawValue: String
    @NSManaged var payload: Data?
    @NSManaged var balanceAdjustmentPayload: Data
    @NSManaged var insertedAt: Date
    @NSManaged var revision: UUID
    @NSManaged var stateRawValue: String
    @NSManaged var failureMessage: String?
}

nonisolated final class CoreDataPendingAccount: NSManagedObject {
    static let entityName = "PendingAccount"

    @NSManaged var accountId: Int64
    @NSManaged var payload: Data
    @NSManaged var insertedAt: Date
    @NSManaged var revision: UUID
    @NSManaged var stateRawValue: String
    @NSManaged var failureMessage: String?
}
