//
//  TransactionEditorToolbar.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import SwiftUI

private enum Constants {
    static var incomeTitle: String {
        AppLocalization.string(
            localized: "Измените доход"
        )
    }
    static var outcomeTitle: String {
        AppLocalization.string(
            localized: "Измените расход"
        )
    }
    static var createIncomeTitle: String {
        AppLocalization.string(
            localized: "Внести доход"
        )
    }
    static var createOutcomeTitle: String {
        AppLocalization.string(
            localized: "Внести расход"
        )
    }
    static let closeIcon = "xmark"
    static let confirmIcon = "checkmark"
    static var closeAccessibilityLabel: String {
        AppLocalization.string(
            localized: "Закрыть"
        )
    }
    static var confirmAccessibilityLabel: String {
        AppLocalization.string(
            localized: "Сохранить изменения"
        )
    }
}

enum TransactionEditorTitle {
    static func value(for mode: TransactionEditorMode) -> String {
        switch mode {
        case let .creation(direction, _):
            switch direction {
            case .income:
                Constants.createIncomeTitle
            case .outcome:
                Constants.createOutcomeTitle
            }

        case let .editing(transaction):
            switch transaction.direction {
            case .income:
                Constants.incomeTitle
            case .outcome:
                Constants.outcomeTitle
            }
        }
    }
}

struct TransactionEditorToolbar: ToolbarContent {
    // MARK: - Properties

    let isProcessing: Bool
    let onDismiss: () -> Void
    let onConfirm: () -> Void

    // MARK: - Toolbar Content

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .cancel, action: onDismiss) {
                Image(systemName: Constants.closeIcon)
                    .foregroundStyle(.primary)
            }
            .accessibilityLabel(
                Constants.closeAccessibilityLabel
            )
            .disabled(isProcessing)
        }

        ToolbarItem(placement: .confirmationAction) {
            Button(action: onConfirm) {
                Group {
                    if isProcessing {
                        ProgressView()
                    } else {
                        Image(systemName: Constants.confirmIcon)
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .clipShape(Circle())
            .accessibilityLabel(
                Constants.confirmAccessibilityLabel
            )
            .disabled(isProcessing)
        }
    }
}
