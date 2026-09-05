//
//  TransactionEditorBottomAccessoryView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import SwiftUI

enum TransactionEditorInputMode: Equatable {
    case idle
    case amount
    case calendar
}

enum TransactionEditorDeleteCopy {
    static var title: String { AppLocalization.string(localized: "Удалить операцию") }
}

private enum Constants {
    static let verticalPadding: CGFloat = 14
}

struct TransactionEditorBottomAccessoryView: View {
    // MARK: - Properties

    let mode: TransactionEditorInputMode
    let showsDeleteAction: Bool
    let decimalSeparator: String
    let isCommentFocused: Bool
    let isProcessing: Bool
    let onDigit: (Int) -> Void
    let onDecimalSeparator: () -> Void
    let onDeleteCharacter: () -> Void
    let onRequestDeletion: () -> Void

    // MARK: - View Body

    @ViewBuilder
    var body: some View {
        switch mode {
        case .amount:
            NumericKeypadView(
                decimalSeparator: decimalSeparator,
                onDigit: onDigit,
                onDecimalSeparator: onDecimalSeparator,
                onDelete: onDeleteCharacter
            )
            .disabled(isProcessing)

        case .calendar:
            EmptyView()

        case .idle:
            if showsDeleteAction {
                deleteButton
                    .opacity(isCommentFocused ? .zero : 1)
                    .allowsHitTesting(!isCommentFocused)
                    .accessibilityHidden(isCommentFocused)
            }
        }
    }

    // MARK: - Private Properties

    private var deleteButton: some View {
        Button(
            TransactionEditorDeleteCopy.title,
            role: .destructive,
            action: onRequestDeletion
        )
        .font(.body.weight(.semibold))
        .padding(.vertical, Constants.verticalPadding)
        .disabled(isProcessing)
    }
}
