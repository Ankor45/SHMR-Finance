//
//  CategoriesListViewModel.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class CategoriesListViewModel {
    // MARK: - Public Properties

    var searchText = String() {
        didSet {
            updateFilteredCategories()
        }
    }
    private(set) var categories: [Category] = []
    private(set) var filteredCategories: [Category] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // MARK: - Private Properties

    private let direction: Direction
    private let service: any CategoryServiceProviding
    private var didLoadCategories = false
    private var searchIndex = FuzzySearchIndex<Category>()

    // MARK: - Initializers

    init(
        direction: Direction,
        service: any CategoryServiceProviding
    ) {
        self.direction = direction
        self.service = service
    }

    // MARK: - Public Methods

    func loadCategoriesIfNeeded() async {
        guard !didLoadCategories, !isLoading else {
            return
        }

        await loadCategories()
    }

    func retry() async {
        guard !isLoading else {
            return
        }

        await loadCategories()
    }

    // MARK: - Private Methods

    private func loadCategories() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let loadedCategories = try await service.getCategories(
                direction: direction
            )
            try Task.checkCancellation()

            searchIndex = FuzzySearchIndex(
                loadedCategories,
                searchableText: \.name
            )
            categories = loadedCategories
            updateFilteredCategories()
            didLoadCategories = true
        } catch is CancellationError {
            return
        } catch {
            categories = []
            filteredCategories = []
            searchIndex = FuzzySearchIndex()
            errorMessage = error.localizedDescription
        }
    }

    private func updateFilteredCategories() {
        filteredCategories = searchIndex.search(
            query: searchText
        )
    }
}
