//
//  AnalyticsViewController+Filters.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 31.07.2026.
//

import UIKit

extension AnalyticsViewController {
    func handleFilterSelection(_ filter: AnalyticsFilterRow) {
        switch filter {
        case .type:
            presentTypeFilter()
        case .period:
            presentPeriodFilter()
        case .categories:
            presentCategoriesFilter()
        case .account:
            presentAccountFilter()
        case .sorting:
            presentSortingFilter()
        }
    }

    private func presentTypeFilter() {
        let filterViewController = AnalyticsTypeFilterViewController(
            selectedDirection: viewModel.filters.direction,
            onSelection: { [weak self] direction in
                guard
                    let self,
                    viewModel.updateDirection(direction)
                else {
                    return
                }

                loadTransactions()
            }
        )
        configureSheet(filterViewController)
        present(filterViewController, animated: true)
    }

    private func presentPeriodFilter() {
        let filterViewController = AnalyticsPeriodFilterViewController(
            startDate: viewModel.filters.startDate,
            endDate: viewModel.filters.endDate,
            onSelection: { [weak self] startDate, endDate in
                self?.applyPeriod(startDate: startDate, endDate: endDate)
            },
            onCustomSelection: { [weak self] in
                self?.presentCustomPeriodFilter()
            }
        )
        configureSheet(filterViewController)
        present(filterViewController, animated: true)
    }

    private func presentCustomPeriodFilter() {
        let filterViewController = AnalyticsDateRangeViewController(
            onSelection: { [weak self] startDate, endDate in
                self?.applyPeriod(
                    startDate: startDate,
                    endDate: endDate
                )
            }
        )
        configureSheet(filterViewController)
        present(filterViewController, animated: true)
    }

    private func presentCategoriesFilter() {
        let filterViewController =
            AnalyticsCategoriesFilterViewController(
                selectedCategoryIDs:
                    viewModel.filters.selectedCategoryIDs,
                loadCategories: { [weak viewModel] in
                    guard let viewModel else {
                        throw CancellationError()
                    }

                    return try await viewModel.loadAvailableCategories()
                },
                onSelection: { [weak self] categoryIDs, categories in
                    self?.applyCategories(
                        categoryIDs,
                        availableCategories: categories
                    )
                }
            )
        configureSheet(filterViewController)
        present(filterViewController, animated: true)
    }

    private func presentAccountFilter() {
        guard viewModel.availableAccounts.isEmpty else {
            showAccountFilter()
            return
        }

        accountFilterTask?.cancel()
        let viewModel = viewModel
        accountFilterTask = Task { [weak self] in
            await viewModel.ensureAccountsAvailable()
            guard !Task.isCancelled else {
                return
            }

            self?.showAccountFilter()
        }
    }

    private func showAccountFilter() {
        guard presentedViewController == nil else {
            return
        }

        let filterViewController = AnalyticsAccountFilterViewController(
            accounts: viewModel.availableAccounts,
            selectedAccountID: viewModel.filters.selectedAccountID,
            onSelection: { [weak self] accountID in
                self?.applyAccount(accountID)
            }
        )
        configureSheet(filterViewController)
        present(filterViewController, animated: true)
    }

    private func presentSortingFilter() {
        let filterViewController = AnalyticsSortingFilterViewController(
            selectedOption: viewModel.filters.sortOption,
            onSelection: { [weak self] sortOption in
                self?.applySortOption(sortOption)
            }
        )
        configureSheet(filterViewController)
        present(filterViewController, animated: true)
    }

    private func configureSheet<Content>(_ viewController: Content)
    where Content: UIViewController & AnalyticsSheetHeightProviding {
        if traitCollection.userInterfaceIdiom == .pad {
            viewController.modalPresentationStyle = .formSheet
        } else {
            viewController.modalPresentationStyle = .custom
            viewController.transitioningDelegate =
                sheetTransitioningDelegate
        }
    }

    private func applyPeriod(startDate: Date, endDate: Date) {
        guard viewModel.updatePeriod(
            startDate: startDate,
            endDate: endDate
        ) else {
            return
        }

        loadTransactions()
    }

    private func applyCategories(
        _ categoryIDs: Set<Int>?,
        availableCategories: [Category]
    ) {
        guard viewModel.updateCategories(
            selectedCategoryIDs: categoryIDs,
            availableCategories: availableCategories
        ) else {
            return
        }

        loadTransactions()
    }

    private func applyAccount(_ accountID: Int?) {
        guard viewModel.updateAccountID(accountID) else {
            return
        }

        loadTransactions()
    }

    private func applySortOption(_ sortOption: AnalyticsSortOption) {
        viewModel.updateSortOption(sortOption)
    }
}
