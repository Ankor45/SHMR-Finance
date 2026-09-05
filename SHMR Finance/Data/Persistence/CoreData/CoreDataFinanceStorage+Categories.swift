//
//  CoreDataFinanceStorage+Categories.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

@preconcurrency import CoreData
import Foundation

extension CoreDataFinanceStorage {
    func getAll() async throws -> [Category] {
        try await perform { try $0.allCategories() }
    }

    func replaceAll(with categories: [Category]) async throws {
        try await perform { session in
            try session.replaceAllCategories(with: categories)
        }
    }

    func upsert(_ categories: [Category]) async throws {
        try await perform { session in
            for category in categories {
                try session.upsertCategory(category)
            }
        }
    }
}

nonisolated extension CoreDataStorageSession {
    func allCategories() throws -> [Category] {
        try fetch(
            CoreDataStoredCategory.self,
            entityName: CoreDataStoredCategory.entityName,
            sortDescriptors: [NSSortDescriptor(key: "categoryId", ascending: true)]
        ).map(category(from:))
    }

    func replaceAllCategories(with categories: [Category]) throws {
        let stored = try fetch(
            CoreDataStoredCategory.self,
            entityName: CoreDataStoredCategory.entityName
        )
        let incoming = Dictionary(
            uniqueKeysWithValues: categories.map { ($0.id, $0) }
        )
        for object in stored {
            guard let category = incoming[Int(object.categoryId)] else {
                context.delete(object)
                continue
            }
            object.payload = try encoder.encode(
                CoreDataCategorySnapshot(category)
            )
        }
        let storedIDs = Set(stored.map { Int($0.categoryId) })
        for category in categories where !storedIDs.contains(category.id) {
            try upsertCategory(category)
        }
    }

    func upsertCategory(_ category: Category) throws {
        let object = try storedCategory(id: category.id)
            ?? CoreDataStoredCategory(
                entity: try entity(named: CoreDataStoredCategory.entityName),
                insertInto: context
            )
        object.categoryId = Int64(category.id)
        object.payload = try encoder.encode(CoreDataCategorySnapshot(category))
    }

    private func storedCategory(id: Int) throws -> CoreDataStoredCategory? {
        try fetch(
            CoreDataStoredCategory.self,
            entityName: CoreDataStoredCategory.entityName,
            predicate: NSPredicate(format: "categoryId == %lld", id)
        ).first
    }

    func entity(named name: String) throws -> NSEntityDescription {
        guard let entity = NSEntityDescription.entity(
            forEntityName: name,
            in: context
        ) else {
            throw FinanceStorageError.coreDataEntityNotFound(name)
        }
        return entity
    }
}
