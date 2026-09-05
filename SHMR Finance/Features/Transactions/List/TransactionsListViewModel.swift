//
//  TransactionsListViewModel.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 18.07.2026.
//

import Foundation
import Observation

enum TransactionsSortOption {
    case date
    case amount

    mutating func toggle() {
        self = self == .date ? .amount : .date
    }
}

@MainActor
@Observable
final class TransactionsListViewModel {
    // MARK: - Public Properties
    var selectedDate: Date
    var sortOption: TransactionsSortOption = .date
    private(set) var transactions: [Transaction] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    let direction: Direction

    var totalAmount: Decimal {
        transactions.reduce(Decimal.zero) { partialResult, transaction in
            partialResult + transaction.amount
        }
    }

    var currencyCode: String {
        transactions.first?.account.currency
            ?? accountsStore.accounts.first?.currency
            ?? CurrencyPresentation.defaultCode
    }

    var sortedTransactions: [Transaction] {
        switch sortOption {
        case .date:
            transactions.sorted { $0.transactionDate > $1.transactionDate }
        case .amount:
            transactions.sorted {
                if $0.amount == $1.amount {
                    return $0.transactionDate > $1.transactionDate
                }

                return $0.amount > $1.amount
            }
        }
    }

    // MARK: - Private Properties

    private let service: any TransactionServiceProviding
    private let accountsStore: AccountsStore
    private let calendar: Calendar
    private var loadedDay: Date?
    private var loadGeneration = 0
    // MARK: - Initializers

    init(
        direction: Direction,
        service: any TransactionServiceProviding,
        accountsStore: AccountsStore,
        selectedDate: Date = Date(),
        calendar: Calendar = .current
    ) {
        self.direction = direction
        self.service = service
        self.accountsStore = accountsStore
        self.selectedDate = selectedDate
        self.calendar = calendar
    }
    // MARK: - Public Methods

    func loadTransactions() async {
        let requestedDay = calendar.startOfDay(for: selectedDate)

        guard loadedDay != requestedDay else {
            return
        }

        loadGeneration += 1
        let currentGeneration = loadGeneration
        loadedDay = nil
        isLoading = true
        errorMessage = nil
        transactions = []
        defer {
            if currentGeneration == loadGeneration {
                isLoading = false
            }
        }

        do {
            let interval = try dayInterval(containing: selectedDate)
            await accountsStore.ensureFresh()
            try Task.checkCancellation()

            if accountsStore.accounts.isEmpty,
               let accountsError = accountsStore.loadErrorMessage {
                errorMessage = accountsError
                return
            }

            let loadedTransactions = try await loadTransactions(
                for: accountsStore.accounts,
                interval: interval
            )
            try Task.checkCancellation()
            guard currentGeneration == loadGeneration else {
                return
            }

            transactions = loadedTransactions
                .filter { $0.direction == direction }
            loadedDay = requestedDay
        } catch is CancellationError {
            return
        } catch {
            guard currentGeneration == loadGeneration else {
                return
            }

            transactions = []
            errorMessage = error.localizedDescription
        }
    }

    func reloadTransactions() async {
        loadedDay = nil
        await loadTransactions()
    }

    func applySavedTransaction(_ transaction: Transaction) {
        transactions.removeAll {
            $0.id == transaction.id
        }

        guard
            transaction.direction == direction,
            calendar.isDate(
                transaction.transactionDate,
                inSameDayAs: selectedDate
            )
        else {
            return
        }

        transactions.append(transaction)
    }

    func removeTransaction(id: Int) {
        transactions.removeAll { $0.id == id }
    }

    // MARK: - Private Methods

    private func dayInterval(containing date: Date) throws -> DateInterval {
        guard let interval = calendar.inclusiveDayInterval(
            from: date,
            through: date
        ) else {
            throw TransactionsListViewModelError.invalidDateInterval
        }

        return interval
    }

    private func loadTransactions(
        for accounts: [BankAccount],
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

            var result: [Transaction] = []

            for try await accountTransactions in group {
                result.append(contentsOf: accountTransactions)
            }

            return result
        }
    }

}

enum TransactionsListViewModelError: LocalizedError {
    case invalidDateInterval

    var errorDescription: String? {
        switch self {
        case .invalidDateInterval:
            AppLocalization.string(localized: "Не удалось определить выбранный день")
        }
    }
}
