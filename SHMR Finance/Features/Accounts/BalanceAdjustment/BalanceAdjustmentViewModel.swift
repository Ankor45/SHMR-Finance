//
//  BalanceAdjustmentViewModel.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class BalanceAdjustmentViewModel {
    // MARK: - Public Properties

    private(set) var isKeypadPresented = false
    private(set) var isSaving = false
    private(set) var errorMessage: String?

    var amountText: String {
        amountInput.text
    }

    var hasStartedEditing: Bool {
        amountInput.hasStartedEditing
    }

    var amount: Decimal {
        amountInput.amount
    }

    // MARK: - Private Properties

    private let amountInput: AmountInputState

    // MARK: - Initializers

    init(initialBalance: Decimal) {
        amountInput = AmountInputState(
            initialAmount: initialBalance
        )
    }

    // MARK: - Public Methods

    func presentKeypad() {
        guard !isSaving else {
            return
        }

        isKeypadPresented = true
    }

    func appendDigit(_ digit: Int) {
        guard !isSaving else {
            return
        }

        amountInput.appendDigit(digit)
    }

    func appendDecimalSeparator() {
        guard !isSaving else {
            return
        }

        amountInput.appendDecimalSeparator()
    }

    func deleteLastCharacter() {
        guard !isSaving else {
            return
        }

        amountInput.deleteLastCharacter()
    }

    func pasteAmount(_ text: String) {
        guard
            !isSaving,
            amountInput.paste(text)
        else {
            return
        }

        isKeypadPresented = true
    }

    func dismissError() {
        errorMessage = nil
    }

    func save(
        using action: (Decimal) async throws -> Void
    ) async -> Bool {
        guard !isSaving else {
            return false
        }

        isKeypadPresented = false
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await action(amount)
            return true
        } catch is CancellationError {
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

}
