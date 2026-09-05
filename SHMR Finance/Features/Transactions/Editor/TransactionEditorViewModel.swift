//
//  TransactionEditorViewModel.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 24.07.2026.
//

import Foundation
import Observation

enum TransactionEditorAlert: Equatable {
    case validation(String)
    case service(String)

    var title: String {
        switch self {
        case .validation:
            AppLocalization.string(localized: "Заполните данные")
        case .service:
            AppLocalization.string(localized: "Не удалось выполнить операцию")
        }
    }

    var message: String {
        switch self {
        case let .validation(message), let .service(message):
            message
        }
    }
}

@MainActor
@Observable
final class TransactionEditorViewModel {
    // MARK: - Public Properties

    let mode: TransactionEditorMode
    let direction: Direction
    let accountSelection: TransactionAccountSelectionViewModel
    private(set) var selectedCategory: Category?
    var commentText: String
    var transactionDate: Date
    private(set) var isProcessing = false
    private(set) var alert: TransactionEditorAlert?

    var isEditing: Bool {
        if case .editing = mode {
            true
        } else {
            false
        }
    }

    var currencyCode: String {
        accountSelection.selectedAccount?.currency
            ?? CurrencyPresentation.defaultCode
    }

    var amountText: String {
        amountInput.text
    }

    var decimalSeparator: String {
        locale.decimalSeparator
            ?? AmountInputState.storageDecimalSeparator
    }

    // MARK: - Private Properties

    private let service: any TransactionServiceProviding
    private let accountsStore: AccountsStore
    private let locale: Locale
    private let now: () -> Date
    private let amountInput: AmountInputState

    // MARK: - Initializers

    init(
        mode: TransactionEditorMode,
        service: any TransactionsScreenServiceProviding,
        accountsStore: AccountsStore,
        locale: Locale = AppLocalization.locale,
        now: @escaping () -> Date = Date.init
    ) {
        self.mode = mode
        self.service = service
        self.accountsStore = accountsStore
        self.locale = locale
        self.now = now
        accountSelection = TransactionAccountSelectionViewModel(
            mode: mode,
            store: accountsStore
        )

        switch mode {
        case let .creation(direction, _):
            self.direction = direction
            selectedCategory = nil
            commentText = String()
            transactionDate = now()
            amountInput = AmountInputState(initialAmount: nil)

        case let .editing(transaction):
            direction = transaction.direction
            selectedCategory = transaction.category
            commentText = transaction.comment ?? String()
            transactionDate = transaction.transactionDate
            amountInput = AmountInputState(
                initialAmount: transaction.amount
            )
        }
    }

    // MARK: - Public Methods

    func selectCategory(_ category: Category) {
        guard category.direction == direction else {
            return
        }

        selectedCategory = category
    }

    func appendDigit(_ digit: Int) {
        guard
            (0...9).contains(digit),
            !isProcessing
        else {
            return
        }

        amountInput.appendDigit(digit)
    }

    func appendDecimalSeparator() {
        guard
            !isProcessing
        else {
            return
        }

        amountInput.appendDecimalSeparator()
    }

    func deleteLastCharacter() {
        guard
            !isProcessing
        else {
            return
        }

        amountInput.deleteLastCharacter()
    }

    func pasteAmount(_ text: String) {
        guard !isProcessing else {
            return
        }

        amountInput.paste(text)
    }

    func save() async -> Transaction? {
        guard !isProcessing else {
            return nil
        }

        guard let amount = validatedAmount() else {
            return nil
        }

        guard let selectedCategory else {
            alert = .validation(
                AppLocalization.string(localized: "Выберите статью операции.")
            )
            return nil
        }

        guard let selectedAccount =
            accountSelection.selectedAccount
        else {
            alert = .validation(
                AppLocalization.string(localized: "Выберите счёт операции.")
            )
            return nil
        }

        guard transactionDate <= now() else {
            alert = .validation(
                AppLocalization.string(
                    localized: "Дата и время операции не могут быть позже текущего момента."
                )
            )
            return nil
        }

        isProcessing = true
        alert = nil
        defer { isProcessing = false }

        do {
            let savedTransaction: Transaction

            switch mode {
            case .creation:
                savedTransaction = try await service.createTransaction(
                    account: selectedAccount,
                    category: selectedCategory,
                    amount: amount,
                    transactionDate: transactionDate,
                    comment: normalizedComment
                )

            case let .editing(transaction):
                savedTransaction = try await service.updateTransaction(
                    transaction,
                    account: selectedAccount,
                    category: selectedCategory,
                    amount: amount,
                    transactionDate: transactionDate,
                    comment: normalizedComment
                )
            }

            accountsStore.invalidateAndRefresh()
            return savedTransaction
        } catch is CancellationError {
            return nil
        } catch {
            alert = .service(error.localizedDescription)
            return nil
        }
    }

    func delete() async -> Int? {
        guard
            !isProcessing,
            case let .editing(transaction) = mode
        else {
            return nil
        }

        isProcessing = true
        alert = nil
        defer { isProcessing = false }

        do {
            try await service.deleteTransaction(
                transaction
            )
            accountsStore.invalidateAndRefresh()
            return transaction.id
        } catch is CancellationError {
            return nil
        } catch {
            alert = .service(error.localizedDescription)
            return nil
        }
    }

    func dismissAlert() {
        alert = nil
    }

    // MARK: - Private Methods

    private func validatedAmount() -> Decimal? {
        guard
            let amount = amountInput.decimalValue,
            amount > .zero
        else {
            alert = .validation(
                AppLocalization.string(localized: "Укажите сумму операции больше нуля.")
            )
            return nil
        }

        return amount
    }

    private var normalizedComment: String? {
        let trimmedComment = commentText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return trimmedComment.isEmpty ? nil : trimmedComment
    }

}
