//
//  TransactionRowView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import SwiftUI

private enum Constants {
    static let horizontalSpacing: CGFloat = 8
    static let textSpacing: CGFloat = 2
    static let trailingSpacing: CGFloat = 8
    static let minimumHeight: CGFloat = 68
    static let lineLimit = 1
    static let fractionDigits = 0...2
    static let titleFont = Font.body
    static let commentFont = Font.caption
    static let amountFont = Font.body
}

struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: Constants.horizontalSpacing) {
            EmojiIconView(emoji: String(transaction.category.emoji))

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(transaction.category.name)
                    .font(Constants.titleFont)
                    .lineLimit(Constants.lineLimit)

                if let comment = transaction.comment,
                   !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(comment)
                        .font(Constants.commentFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(Constants.lineLimit)
                }
            }

            Spacer(minLength: Constants.trailingSpacing)

            Text(
                CurrencyPresentation.formattedAmount(
                    transaction.amount,
                    currencyCode: transaction.account.currency,
                    fractionDigits: Constants.fractionDigits
                )
            )
            .font(Constants.amountFont)
            .lineLimit(Constants.lineLimit)
        }
        .frame(minHeight: Constants.minimumHeight)
        .contentShape(Rectangle())
    }
}
