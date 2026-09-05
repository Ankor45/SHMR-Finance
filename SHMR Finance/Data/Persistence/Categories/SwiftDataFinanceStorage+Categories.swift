//
//  SwiftDataFinanceStorage+Categories.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation
import SwiftData

extension SwiftDataFinanceStorage {
    func getAll() throws -> [Category] {
        let descriptor = FetchDescriptor<StoredCategory>(
            sortBy: [SortDescriptor(\.categoryId)]
        )
        return try modelContext.fetch(descriptor).map { try $0.toDomain() }
    }

    func replaceAll(with categories: [Category]) throws {
        let storedCategories = try modelContext.fetch(
            FetchDescriptor<StoredCategory>()
        )
        let categoriesByID = Dictionary(
            uniqueKeysWithValues: categories.map { ($0.id, $0) }
        )

        for storedCategory in storedCategories {
            guard let category = categoriesByID[storedCategory.categoryId] else {
                modelContext.delete(storedCategory)
                continue
            }
            storedCategory.update(with: category)
        }

        let storedIDs = Set(storedCategories.map(\.categoryId))
        for category in categories where !storedIDs.contains(category.id) {
            modelContext.insert(StoredCategory(category: category))
        }
        try saveChanges()
    }

    func upsert(_ categories: [Category]) throws {
        for category in categories {
            if let storedCategory = try findStoredCategory(id: category.id) {
                storedCategory.update(with: category)
            } else {
                modelContext.insert(StoredCategory(category: category))
            }
        }
        try saveChanges()
    }

    private func findStoredCategory(id: Int) throws -> StoredCategory? {
        let categoryId = id
        var descriptor = FetchDescriptor<StoredCategory>(
            predicate: #Predicate { category in
                category.categoryId == categoryId
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
