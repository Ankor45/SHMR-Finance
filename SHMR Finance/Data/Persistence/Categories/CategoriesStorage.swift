//
//  CategoriesStorage.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

nonisolated protocol CategoriesStorage: Sendable {
    func getAll() async throws -> [Category]
    func replaceAll(with categories: [Category]) async throws
    func upsert(_ categories: [Category]) async throws
}
