//
//  NumericKeypadView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import Foundation
import SwiftUI

private enum KeypadKey: Hashable {
    case digit(Int)
    case decimalSeparator
    case delete
}

private enum Constants {
    static let rows: [[KeypadKey]] = [
        [.digit(1), .digit(2), .digit(3)],
        [.digit(4), .digit(5), .digit(6)],
        [.digit(7), .digit(8), .digit(9)],
        [.decimalSeparator, .digit(0), .delete]
    ]

    static var decimalSeparatorAccessibilityLabel: String {
        AppLocalization.string(
            localized: "Десятичный разделитель"
        )
    }
    static let deleteIcon = "delete.left"
    static var deleteAccessibilityLabel: String {
        AppLocalization.string(
            localized: "Удалить цифру"
        )
    }
    static let horizontalSpacing: CGFloat = 6
    static let verticalSpacing: CGFloat = 6
    static let horizontalPadding: CGFloat = 6
    static let verticalPadding: CGFloat = 8
    static let keyHeight: CGFloat = 48
    static let keyCornerRadius: CGFloat = 6
    static let keyFont = Font.title2
    static let keyBackground = Color(.systemBackground)
    static let keypadBackground = Color(.systemGray6)
}

struct NumericKeypadAccessoryAction {
    let iconName: String
    let accessibilityLabel: String
    let action: () -> Void
}

struct NumericKeypadView: View {
    // MARK: - Properties

    @Environment(HapticsService.self) private var hapticsService

    private let decimalSeparator: String
    private let onDecimalSeparator: (() -> Void)?
    private let accessoryAction: NumericKeypadAccessoryAction?
    private let isInputEnabled: Bool
    let onDigit: (Int) -> Void
    let onDelete: () -> Void

    // MARK: - Initializers

    init(
        decimalSeparator: String = AppLocalization.locale.decimalSeparator
            ?? ",",
        isInputEnabled: Bool = true,
        accessoryAction: NumericKeypadAccessoryAction? = nil,
        onDigit: @escaping (Int) -> Void,
        onDecimalSeparator: (() -> Void)? = nil,
        onDelete: @escaping () -> Void
    ) {
        self.decimalSeparator = decimalSeparator
        self.isInputEnabled = isInputEnabled
        self.accessoryAction = accessoryAction
        self.onDigit = onDigit
        self.onDecimalSeparator = onDecimalSeparator
        self.onDelete = onDelete
    }

    // MARK: - View Body

    var body: some View {
        Grid(
            horizontalSpacing: Constants.horizontalSpacing,
            verticalSpacing: Constants.verticalSpacing
        ) {
            ForEach(Constants.rows.indices, id: \.self) { rowIndex in
                GridRow {
                    ForEach(
                        Constants.rows[rowIndex],
                        id: \.self
                    ) { key in
                        keyView(for: key)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
        .background(
            Constants.keypadBackground,
            ignoresSafeAreaEdges: .bottom
        )
    }

    // MARK: - Private Methods

    @ViewBuilder
    private func keyView(for key: KeypadKey) -> some View {
        switch key {
        case let .digit(digit):
            keypadButton(
                accessibilityLabel: String(digit),
                action: { onDigit(digit) }
            ) {
                Text(String(digit))
            }
            .disabled(!isInputEnabled)

        case .delete:
            if let accessoryAction {
                keypadButton(
                    accessibilityLabel:
                        accessoryAction.accessibilityLabel,
                    action: accessoryAction.action
                ) {
                    Image(systemName: accessoryAction.iconName)
                }
            } else {
                keypadButton(
                    accessibilityLabel: Constants.deleteAccessibilityLabel,
                    action: onDelete
                ) {
                    Image(systemName: Constants.deleteIcon)
                }
                .disabled(!isInputEnabled)
            }

        case .decimalSeparator:
            if let onDecimalSeparator {
                keypadButton(
                    accessibilityLabel:
                        Constants.decimalSeparatorAccessibilityLabel,
                    action: onDecimalSeparator
                ) {
                    Text(decimalSeparator)
                }
                .disabled(!isInputEnabled)
            } else {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: Constants.keyHeight)
                    .accessibilityHidden(true)
            }
        }
    }

    private func keypadButton<Label: View>(
        accessibilityLabel: String,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) -> some View {
        Button {
            hapticsService.keyPressOccurred()
            action()
        } label: {
            label()
                .font(Constants.keyFont)
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity)
                .frame(height: Constants.keyHeight)
                .background(
                    Constants.keyBackground,
                    in: RoundedRectangle(
                        cornerRadius: Constants.keyCornerRadius
                    )
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
