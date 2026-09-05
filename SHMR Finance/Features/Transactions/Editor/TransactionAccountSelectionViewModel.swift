//
//  TransactionAccountSelectionViewModel.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class TransactionAccountSelectionViewModel {
    private(set) var selectedAccount: BankAccount?

    var accounts: [BankAccount] {
        if store.accounts.isEmpty,
           let initialAccount {
            [initialAccount]
        } else {
            store.accounts
        }
    }

    var isLoading: Bool {
        store.isLoading
    }

    var errorMessage: String? {
        store.errorMessage
    }

    var loadErrorMessage: String? {
        store.loadErrorMessage
    }

    private let store: AccountsStore
    private let preferredAccountID: Int?
    private let initialAccount: BankAccount?

    init(
        mode: TransactionEditorMode,
        store: AccountsStore
    ) {
        self.store = store

        switch mode {
        case let .creation(_, preferredAccountID):
            selectedAccount = nil
            self.preferredAccountID = preferredAccountID
            initialAccount = nil

        case let .editing(transaction):
            selectedAccount = transaction.account
            preferredAccountID = transaction.account.id
            initialAccount = transaction.account
        }
    }

    func select(_ account: BankAccount) {
        guard
            accounts.contains(where: { $0.id == account.id })
        else {
            return
        }

        selectedAccount = account
    }

    func loadIfNeeded() async {
        await store.ensureFresh()
        synchronizeSelection()
    }

    func retry() async {
        await store.retry()
        synchronizeSelection()
    }

    func dismissError() {
        store.dismissError()
    }

    private func synchronizeSelection() {
        if let selectedAccount,
           let refreshedAccount = store.accounts.first(
               where: { $0.id == selectedAccount.id }
           ) {
            self.selectedAccount = refreshedAccount
            return
        }

        guard selectedAccount == nil else {
            return
        }

        selectedAccount = store.accounts.first {
            $0.id == preferredAccountID
        }
    }
}
