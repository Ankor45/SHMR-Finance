//
//  BalanceAmountInputView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import SwiftUI

private enum Constants {
    static let zero = "0"
    static let storageDecimalSeparator = "."
    static let fieldWidth: CGFloat = 220
    static let contentSpacing: CGFloat = 2
    static let cursorWidth: CGFloat = 2
    static let cursorHeight: CGFloat = 40
    static let cursorBlinkDuration: TimeInterval = 0.25
    static let underlineHeight: CGFloat = 0.5
    static let minimumScaleFactor = 0.5
    static let lineLimit = 1
    static let font = Font.largeTitle.bold()
    static let underlineColor = Color(.separator)
    static let parsingLocale = AppLocale.posix
}

struct BalanceAmountInputView: View {
    // MARK: - Properties

    let amountText: String
    let currencySymbol: String
    let isCurrencyVisible: Bool
    let isActive: Bool
    let isCursorAfterCurrency: Bool
    let isDisabled: Bool
    private let locale: Locale
    let onTap: () -> Void
    let onPaste: (String) -> Void

    // MARK: - Initializers

    init(
        amountText: String,
        currencySymbol: String,
        isCurrencyVisible: Bool,
        isActive: Bool,
        isCursorAfterCurrency: Bool = false,
        isDisabled: Bool,
        locale: Locale = AppLocalization.locale,
        onTap: @escaping () -> Void,
        onPaste: @escaping (String) -> Void
    ) {
        self.amountText = amountText
        self.currencySymbol = currencySymbol
        self.isCurrencyVisible = isCurrencyVisible
        self.isActive = isActive
        self.isCursorAfterCurrency = isCursorAfterCurrency
        self.isDisabled = isDisabled
        self.locale = locale
        self.onTap = onTap
        self.onPaste = onPaste
    }

    // MARK: - View Body

    var body: some View {
        HStack(spacing: Constants.contentSpacing) {
            Text(formattedAmount)

            if isActive && !isCursorAfterCurrency {
                inputCursor
            }

            if isCurrencyVisible {
                Text(currencySymbol)
            }

            if isActive && isCursorAfterCurrency {
                inputCursor
            }
        }
        .font(Constants.font)
        .foregroundStyle(
            amountText.isEmpty
                ? Color.secondary
                : Color.primary
        )
        .lineLimit(Constants.lineLimit)
        .minimumScaleFactor(Constants.minimumScaleFactor)
        .frame(width: Constants.fieldWidth)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Constants.underlineColor)
                .frame(
                    width: Constants.fieldWidth,
                    height: Constants.underlineHeight
                )
        }
        .overlay {
            NativePasteMenuView(
                isEnabled: !isDisabled,
                onTap: onTap,
                onPaste: onPaste
            )
        }
        .contentShape(Rectangle())
        .opacity(isDisabled ? 0.5 : 1)
        .accessibilityElement()
        .accessibilityLabel(AppLocalization.string(localized: "Изменить сумму"))
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            guard !isDisabled else {
                return
            }

            onTap()
        }
    }

    // MARK: - Private Properties

    private var formattedAmount: String {
        let components = amountText.split(
            separator: Character(Constants.storageDecimalSeparator),
            maxSplits: 1,
            omittingEmptySubsequences: false
        )
        let integerText = components.first.map(String.init) ?? Constants.zero
        let integerAmount = Decimal(
            string: integerText.isEmpty ? Constants.zero : integerText,
            locale: Constants.parsingLocale
        ) ?? .zero
        let formattedInteger = integerAmount.formatted(
            .number
                .grouping(.automatic)
                .precision(.fractionLength(0))
                .locale(locale)
        )

        guard components.count == 2 else {
            return formattedInteger
        }

        return formattedInteger
            + (
                locale.decimalSeparator
                ?? Constants.storageDecimalSeparator
            )
            + components[1]
    }

    private var accessibilityValue: String {
        guard !amountText.isEmpty else {
            return AppLocalization.string(localized: "Сумма не указана")
        }

        guard isCurrencyVisible else {
            return formattedAmount
        }

        return "\(formattedAmount) \(currencySymbol)"
    }

    private var inputCursor: some View {
        Rectangle()
            .fill(.tint)
            .frame(
                width: Constants.cursorWidth,
                height: Constants.cursorHeight
            )
            .phaseAnimator([true, false]) { cursor, isVisible in
                cursor.opacity(isVisible ? 1 : 0)
            } animation: { _ in
                .easeInOut(duration: Constants.cursorBlinkDuration)
            }
            .accessibilityHidden(true)
    }
}
