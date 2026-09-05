//
//  CategoryDTO+Mapping.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 15.07.2026.
//

import Foundation

nonisolated extension CategoryDTO {
    func toDomain() -> Category {
        Category(
            id: id,
            name: name,
            emoji: emoji.first ?? "❓",
            direction: isIncome ? .income : .outcome
        )
    }
}
