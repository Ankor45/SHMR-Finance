//
//  AccountRowView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import SwiftUI

private enum Constants {
    static let horizontalSpacing: CGFloat = 8
    static let trailingSpacing: CGFloat = 8
    static let minimumHeight: CGFloat = 68
    static let lineLimit = 1
    static var hiddenBalanceAccessibilityValue: String {
        AppLocalization.string(
            localized: "Баланс скрыт"
        )
    }
    static var accessibilityHint: String {
        AppLocalization.string(
            localized: "Открывает корректировку баланса"
        )
    }
    static let titleFont = Font.body
    static let amountFont = Font.body
    static let fractionDigits = 0...2
}

struct AccountRowView: View {
    // MARK: - Properties

    let account: BankAccount
    let isBalanceHidden: Bool
    let onTap: () -> Void

    // MARK: - View Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Constants.horizontalSpacing) {
                EmojiIconView(emoji: account.emoji)

                Text(account.name)
                    .font(Constants.titleFont)
                    .lineLimit(Constants.lineLimit)

                Spacer(minLength: Constants.trailingSpacing)

                AnimatedSpoilerView(isHidden: isBalanceHidden) {
                    Text(
                        CurrencyPresentation.formattedAmount(
                            account.balance,
                            currencyCode: account.currency,
                            fractionDigits: Constants.fractionDigits
                        )
                    )
                    .font(Constants.amountFont)
                    .lineLimit(Constants.lineLimit)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: Constants.minimumHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(account.name)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(Constants.accessibilityHint)
    }

    private var accessibilityValue: String {
        guard !isBalanceHidden else {
            return Constants.hiddenBalanceAccessibilityValue
        }

        return CurrencyPresentation.formattedAmount(
            account.balance,
            currencyCode: account.currency,
            fractionDigits: Constants.fractionDigits
        )
    }
}
