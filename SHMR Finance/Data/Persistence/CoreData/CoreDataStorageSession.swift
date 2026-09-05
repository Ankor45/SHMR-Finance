//
//  CoreDataStorageSession.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

@preconcurrency import CoreData
import Foundation

nonisolated final class CoreDataStorageSession {
    let context: NSManagedObjectContext
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetch<T: NSManagedObject>(
        _ type: T.Type,
        entityName: String,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor] = []
    ) throws -> [T] {
        let request = NSFetchRequest<T>(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return try context.fetch(request)
    }

    func deleteAll<T: NSManagedObject>(
        _ type: T.Type,
        entityName: String
    ) throws {
        for object in try fetch(type, entityName: entityName) {
            context.delete(object)
        }
    }

    func transaction(from object: CoreDataStoredTransaction) throws
        -> Transaction {
        do {
            return try decoder.decode(
                TransactionSnapshot.self,
                from: object.payload
            ).toDomain()
        } catch {
            throw FinanceStorageError.invalidStoredTransaction(
                id: Int(object.transactionId)
            )
        }
    }

    func transactionPayload(_ transaction: Transaction) throws -> Data {
        try encoder.encode(TransactionSnapshot(transaction: transaction))
    }

    func account(from object: CoreDataStoredAccount) throws -> BankAccount {
        do {
            return try decoder.decode(BankAccount.self, from: object.payload)
        } catch {
            throw FinanceStorageError.invalidStoredAccount(
                id: Int(object.accountId)
            )
        }
    }

    func category(from object: CoreDataStoredCategory) throws -> Category {
        do {
            let snapshot = try decoder.decode(
                CoreDataCategorySnapshot.self,
                from: object.payload
            )
            return try snapshot.toDomain()
        } catch {
            throw FinanceStorageError.invalidStoredCategory(
                id: Int(object.categoryId)
            )
        }
    }
}

nonisolated struct CoreDataCategorySnapshot: Codable, Sendable {
    let id: Int
    let name: String
    let emoji: String
    let isIncome: Bool

    init(_ category: Category) {
        id = category.id
        name = category.name
        emoji = String(category.emoji)
        isIncome = category.direction == .income
    }

    func toDomain() throws -> Category {
        guard let emoji = emoji.first else {
            throw FinanceStorageError.invalidStoredCategory(id: id)
        }
        return Category(
            id: id,
            name: name,
            emoji: emoji,
            direction: isIncome ? .income : .outcome
        )
    }
}
