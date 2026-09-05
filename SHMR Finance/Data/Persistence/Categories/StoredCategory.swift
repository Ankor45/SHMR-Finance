//
//  StoredCategory.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation
import SwiftData

@Model
nonisolated final class StoredCategory {
    @Attribute(.unique) var categoryId: Int
    var name: String
    var emoji: String
    var isIncome: Bool

    init(category: Category) {
        categoryId = category.id
        name = category.name
        emoji = String(category.emoji)
        isIncome = category.direction == .income
    }

    func update(with category: Category) {
        name = category.name
        emoji = String(category.emoji)
        isIncome = category.direction == .income
    }

    func toDomain() throws -> Category {
        guard let emoji = emoji.first else {
            throw FinanceStorageError.invalidStoredCategory(
                id: categoryId
            )
        }

        return Category(
            id: categoryId,
            name: name,
            emoji: emoji,
            direction: isIncome ? .income : .outcome
        )
    }
}
