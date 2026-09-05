//
//  CategoriesService.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation
import OSLog

nonisolated final class CategoriesService:
    CategoryServiceProviding,
    Sendable {
    private let dataProvider: any CategoryDataProviding
    private let storage: any CategoriesStorage
    private let dataSourceStatus: any DataSourceStatusReporting

    private static let logger = AppLogger.make(category: "CategoriesService")

    init(
        dataProvider: any CategoryDataProviding,
        storage: any CategoriesStorage,
        dataSourceStatus: any DataSourceStatusReporting
    ) {
        self.dataProvider = dataProvider
        self.storage = storage
        self.dataSourceStatus = dataSourceStatus
    }

    func getCategories() async throws -> [Category] {
        let categories: [Category]

        do {
            let categoryDTOs = try await dataProvider.fetchCategories()
            categories = categoryDTOs.map { $0.toDomain() }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            guard Self.allowsLocalFallback(for: error) else {
                throw error
            }

            let cachedCategories = try await storage.getAll()
            await dataSourceStatus.didLoadLocalData(for: .categories)
            return cachedCategories
        }

        do {
            try await storage.replaceAll(with: categories)
        } catch {
            Self.logCacheError(error, operation: "replace categories")
        }
        await dataSourceStatus.didLoadRemoteData(for: .categories)
        return categories
    }

    func getCategories(direction: Direction) async throws -> [Category] {
        let categories: [Category]

        do {
            let categoryDTOs = try await dataProvider.fetchCategories(
                direction: direction
            )
            categories = categoryDTOs.map { $0.toDomain() }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            guard Self.allowsLocalFallback(for: error) else {
                throw error
            }

            let cachedCategories = try await storage.getAll()
            await dataSourceStatus.didLoadLocalData(for: .categories)
            return cachedCategories.filter {
                $0.direction == direction
            }
        }

        do {
            try await storage.upsert(categories)
        } catch {
            Self.logCacheError(error, operation: "upsert categories")
        }
        await dataSourceStatus.didLoadRemoteData(for: .categories)
        return categories
    }

    private static func allowsLocalFallback(for error: Error) -> Bool {
        (error as? NetworkError)?.allowsLocalFallback == true
    }

    private static func logCacheError(
        _ error: Error,
        operation: String
    ) {
        logger.error(
            "Local cache failed during \(operation, privacy: .public): \(error.localizedDescription, privacy: .public)"
        )
    }
}
