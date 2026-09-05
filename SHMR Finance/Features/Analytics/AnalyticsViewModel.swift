//
//  AnalyticsViewModel.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 29.07.2026.
//

import Foundation

@MainActor
final class AnalyticsViewModel {
    // MARK: - Public Properties

    private(set) var filters: AnalyticsFilterState
    private(set) var transactions: [Transaction] = []
    private(set) var state: AnalyticsLoadState = .loading {
        didSet {
            onChange?()
        }
    }
    var onChange: (() -> Void)?

    var totalAmount: Decimal {
        transactions.reduce(.zero) { result, transaction in
            result + transaction.amount
        }
    }

    var currencyCode: String {
        transactions.first?.account.currency
            ?? selectedAccount?.currency
            ?? accountsStore.accounts.first?.currency
            ?? CurrencyPresentation.defaultCode
    }

    var selectedAccountName: String? {
        selectedAccount?.name
    }

    var availableAccounts: [BankAccount] {
        accountsStore.accounts
    }

    var selectedCategoryNames: [String] {
        guard let selectedCategoryIDs = filters.selectedCategoryIDs else {
            return []
        }

        return selectedCategoryIDs
            .compactMap { categoryNamesByID[$0] }
            .sorted {
                $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
            }
    }

    var chartItems: [AnalyticsChartItem] {
        var amountsByCategoryID: [Int: Decimal] = [:]
        var namesByCategoryID: [Int: String] = [:]

        for transaction in transactions {
            let categoryID = transaction.category.id
            amountsByCategoryID[categoryID, default: .zero] +=
                transaction.amount
            namesByCategoryID[categoryID] = transaction.category.name
        }

        return amountsByCategoryID.compactMap { categoryID, amount in
            guard let name = namesByCategoryID[categoryID] else {
                return nil
            }
            return AnalyticsChartItem(value: amount, label: name)
        }
        .sorted {
            if $0.value != $1.value {
                return $0.value > $1.value
            }
            return $0.label.localizedCaseInsensitiveCompare($1.label)
                == .orderedAscending
        }
    }

    var viewState: AnalyticsViewState {
        AnalyticsViewState(
            filters: filters,
            transactions: transactions,
            loadState: state,
            totalAmount: totalAmount,
            currencyCode: currencyCode,
            selectedCategoryNames: selectedCategoryNames,
            selectedAccountName: selectedAccountName,
            chartItems: chartItems
        )
    }

    // MARK: - Private Properties

    private let service: any TransactionsScreenServiceProviding
    private let accountsStore: AccountsStore
    private let calendar: Calendar
    private var loadGeneration = 0
    private var categoryNamesByID: [Int: String] = [:]

    // MARK: - Initializers

    init(
        initialDirection: Direction,
        service: any TransactionsScreenServiceProviding,
        accountsStore: AccountsStore,
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        self.service = service
        self.accountsStore = accountsStore
        self.calendar = calendar
        filters = AnalyticsFilterState(
            initialDirection: initialDirection,
            now: now,
            calendar: calendar
        )
    }

    // MARK: - Public Methods

    func beginLoading() {
        loadGeneration &+= 1
        transactions = []
        state = .loading
    }

    func loadTransactions() async {
        let currentGeneration = loadGeneration

        do {
            try Task.checkCancellation()
            guard currentGeneration == loadGeneration else {
                return
            }

            let interval = try selectedDateInterval()

            await accountsStore.ensureFresh()
            try Task.checkCancellation()

            guard currentGeneration == loadGeneration else {
                return
            }

            resetUnavailableAccountFilterIfNeeded()

            if accountsStore.accounts.isEmpty,
               let errorMessage = accountsStore.loadErrorMessage {
                state = .failed(errorMessage)
                return
            }

            let loadedTransactions = try await loadTransactions(
                accounts: filteredAccounts,
                interval: interval
            )
            try Task.checkCancellation()

            guard currentGeneration == loadGeneration else {
                return
            }

            updateCategoryNames(from: loadedTransactions)

            var seenTransactionIDs = Set<Int>()
            transactions = loadedTransactions
                .filter(matchesFilters)
                .filter {
                    seenTransactionIDs.insert($0.id).inserted
                }
                .sorted(by: shouldOrderBefore)
            state = .loaded
        } catch is CancellationError {
            return
        } catch {
            guard currentGeneration == loadGeneration else {
                return
            }

            transactions = []
            state = .failed(error.localizedDescription)
        }
    }

    func cancelLoading() {
        loadGeneration &+= 1
    }

    @discardableResult
    func updateDirection(_ direction: Direction?) -> Bool {
        guard filters.direction != direction else {
            return false
        }

        filters.direction = direction
        filters.selectedCategoryIDs = nil
        categoryNamesByID = [:]
        return true
    }

    @discardableResult
    func updatePeriod(startDate: Date, endDate: Date) -> Bool {
        let firstDate = calendar.startOfDay(for: startDate)
        let secondDate = calendar.startOfDay(for: endDate)
        let normalizedStartDate = min(firstDate, secondDate)
        let normalizedEndDate = max(firstDate, secondDate)

        guard
            filters.startDate != normalizedStartDate
                || filters.endDate != normalizedEndDate
        else {
            return false
        }

        filters.startDate = normalizedStartDate
        filters.endDate = normalizedEndDate
        return true
    }

    @discardableResult
    func updateAccountID(_ accountID: Int?) -> Bool {
        if let accountID,
           !accountsStore.accounts.contains(where: { $0.id == accountID }) {
            return false
        }
        guard filters.selectedAccountID != accountID else {
            return false
        }

        filters.selectedAccountID = accountID
        return true
    }

    @discardableResult
    func updateSortOption(_ sortOption: AnalyticsSortOption) -> Bool {
        guard filters.sortOption != sortOption else {
            return false
        }

        filters.sortOption = sortOption
        transactions.sort(by: shouldOrderBefore)
        onChange?()
        return true
    }

    @discardableResult
    func updateCategories(
        selectedCategoryIDs: Set<Int>?,
        availableCategories: [Category]
    ) -> Bool {
        let updatedNamesByID = availableCategories.reduce(into: [:]) {
            result, category in
            result[category.id] = category.name
        }
        let didChange = filters.selectedCategoryIDs != selectedCategoryIDs
            || categoryNamesByID != updatedNamesByID

        guard didChange else {
            return false
        }

        categoryNamesByID = updatedNamesByID
        filters.selectedCategoryIDs = selectedCategoryIDs
        return true
    }

    func loadAvailableCategories() async throws -> [Category] {
        if let direction = filters.direction {
            return try await service.getCategories(direction: direction)
        }

        return try await service.getCategories()
    }

    func ensureAccountsAvailable() async {
        await accountsStore.ensureFresh()
    }

    // MARK: - Private Properties

    private var selectedAccount: BankAccount? {
        guard let selectedAccountID = filters.selectedAccountID else {
            return nil
        }

        return accountsStore.accounts.first {
            $0.id == selectedAccountID
        }
    }

    private var filteredAccounts: [BankAccount] {
        guard filters.selectedAccountID != nil else {
            return accountsStore.accounts
        }

        return selectedAccount.map { [$0] } ?? []
    }

    // MARK: - Private Methods

    private func selectedDateInterval() throws -> DateInterval {
        guard let interval = calendar.inclusiveDayInterval(
            from: filters.startDate,
            through: filters.endDate
        ) else {
            throw AnalyticsViewModelError.invalidDateInterval
        }

        return interval
    }

    private func resetUnavailableAccountFilterIfNeeded() {
        guard
            let selectedAccountID = filters.selectedAccountID,
            !accountsStore.accounts.contains(where: {
                $0.id == selectedAccountID
            })
        else {
            return
        }

        filters.selectedAccountID = nil
    }

    private func loadTransactions(
        accounts: [BankAccount],
        interval: DateInterval
    ) async throws -> [Transaction] {
        try await withThrowingTaskGroup(
            of: [Transaction].self,
            returning: [Transaction].self
        ) { group in
            for account in accounts {
                group.addTask { [service] in
                    try await service.getTransactions(
                        account: account,
                        from: interval.start,
                        to: interval.end
                    )
                }
            }

            var transactions: [Transaction] = []

            for try await accountTransactions in group {
                transactions.append(contentsOf: accountTransactions)
            }

            return transactions
        }
    }

    private func matchesFilters(_ transaction: Transaction) -> Bool {
        let matchesDirection = filters.direction.map {
            transaction.direction == $0
        } ?? true
        let matchesCategory = filters.selectedCategoryIDs.map {
            $0.contains(transaction.category.id)
        } ?? true

        return matchesDirection && matchesCategory
    }

    private func updateCategoryNames(
        from transactions: [Transaction]
    ) {
        for transaction in transactions {
            categoryNamesByID[transaction.category.id] =
                transaction.category.name
        }
    }

    private func shouldOrderBefore(
        _ lhs: Transaction,
        _ rhs: Transaction
    ) -> Bool {
        switch filters.sortOption {
        case .date:
            if lhs.transactionDate == rhs.transactionDate {
                return lhs.id > rhs.id
            }

            return lhs.transactionDate > rhs.transactionDate
        case .amount:
            if lhs.amount != rhs.amount {
                return lhs.amount > rhs.amount
            }
            if lhs.transactionDate != rhs.transactionDate {
                return lhs.transactionDate > rhs.transactionDate
            }

            return lhs.id > rhs.id
        }
    }
}

enum AnalyticsViewModelError: LocalizedError {
    case invalidDateInterval

    var errorDescription: String? {
        switch self {
        case .invalidDateInterval:
            AppLocalization.string(localized: "Не удалось определить выбранный период")
        }
    }
}
