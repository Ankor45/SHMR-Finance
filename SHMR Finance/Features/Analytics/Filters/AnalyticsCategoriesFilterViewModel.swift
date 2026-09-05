//
//  AnalyticsCategoriesFilterViewModel.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import Foundation

@MainActor
final class AnalyticsCategoriesFilterViewModel {
    // MARK: - Properties

    private(set) var categories: [Category] = []
    private(set) var selectedCategoryIDs: Set<Int> = []
    private(set) var state: AnalyticsLoadState = .loading {
        didSet {
            onStateChange?()
        }
    }
    var onStateChange: (() -> Void)?

    var appliedCategoryIDs: Set<Int>? {
        selectedCategoryIDs == availableCategoryIDs
            ? nil
            : selectedCategoryIDs
    }

    var areAllCategoriesSelected: Bool {
        guard !categories.isEmpty else {
            return false
        }

        return selectedCategoryIDs == availableCategoryIDs
    }

    // MARK: - Private Properties

    private let initialCategoryIDs: Set<Int>?
    private let loadCategories: () async throws -> [Category]
    private var availableCategoryIDs: Set<Int> = []
    private var loadGeneration = 0

    // MARK: - Initializers

    init(
        selectedCategoryIDs: Set<Int>?,
        loadCategories: @escaping () async throws -> [Category]
    ) {
        initialCategoryIDs = selectedCategoryIDs
        self.loadCategories = loadCategories
    }

    // MARK: - Methods

    func load() async {
        loadGeneration &+= 1
        let currentGeneration = loadGeneration
        state = .loading

        do {
            let loadedCategories = try await loadCategories()
            try Task.checkCancellation()
            guard currentGeneration == loadGeneration else {
                return
            }

            categories = Self.removingDuplicates(from: loadedCategories)
            availableCategoryIDs = Set(categories.map(\.id))
            selectedCategoryIDs = initialCategoryIDs.map {
                $0.intersection(availableCategoryIDs)
            } ?? availableCategoryIDs
            state = .loaded
        } catch is CancellationError {
            return
        } catch {
            guard currentGeneration == loadGeneration else {
                return
            }

            categories = []
            selectedCategoryIDs = []
            availableCategoryIDs = []
            state = .failed(error.localizedDescription)
        }
    }

    func cancelLoading() {
        loadGeneration &+= 1
    }

    func toggleCategory(at index: Int) {
        guard categories.indices.contains(index) else {
            return
        }

        let categoryID = categories[index].id
        if selectedCategoryIDs.contains(categoryID) {
            selectedCategoryIDs.remove(categoryID)
        } else {
            selectedCategoryIDs.insert(categoryID)
        }
        onStateChange?()
    }

    func toggleAllCategories() {
        guard !categories.isEmpty else {
            return
        }

        selectedCategoryIDs = areAllCategoriesSelected
            ? []
            : availableCategoryIDs
        onStateChange?()
    }

    func isSelected(_ category: Category) -> Bool {
        selectedCategoryIDs.contains(category.id)
    }

    private static func removingDuplicates(
        from categories: [Category]
    ) -> [Category] {
        var seenIDs = Set<Int>()
        return categories.filter {
            seenIDs.insert($0.id).inserted
        }
    }
}
