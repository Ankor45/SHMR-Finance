//
//  TotalSummaryView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import SwiftUI

private enum Constants {
    static let spacing: CGFloat = 4
    static let horizontalPadding: CGFloat = 20
    static let topPadding: CGFloat = 20
    static let bottomPadding: CGFloat = 16
    static let headerHeight: CGFloat = 44
    static let fractionDigits = 0...2
    static let titleFont = Font.subheadline
    static let amountFont = Font.largeTitle.bold()
}

struct TotalSummaryView<Trailing: View>: View {
    // MARK: - Properties

    let title: String
    let amount: Decimal
    let currencyCode: String
    let isAmountHidden: Bool
    private let trailing: Trailing
    // MARK: - Initializers

    init(
        title: String,
        amount: Decimal,
        currencyCode: String,
        isAmountHidden: Bool = false,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.amount = amount
        self.currencyCode = currencyCode
        self.isAmountHidden = isAmountHidden
        self.trailing = trailing()
    }
    // MARK: - View Body

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            HStack {
                Text(title)
                    .font(Constants.titleFont)
                    .foregroundStyle(.secondary)
                    .textCase(.lowercase)

                Spacer()

                trailing
            }
            .frame(minHeight: Constants.headerHeight)

            AnimatedSpoilerView(isHidden: isAmountHidden) {
                Text(
                    CurrencyPresentation.formattedAmount(
                        amount,
                        currencyCode: currencyCode,
                        fractionDigits: Constants.fractionDigits
                    )
                )
                .font(Constants.amountFont)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.top, Constants.topPadding)
        .padding(.bottom, Constants.bottomPadding)
    }
}

extension TotalSummaryView where Trailing == EmptyView {
    init(
        title: String,
        amount: Decimal,
        currencyCode: String,
        isAmountHidden: Bool = false
    ) {
        self.init(
            title: title,
            amount: amount,
            currencyCode: currencyCode,
            isAmountHidden: isAmountHidden,
            trailing: EmptyView.init
        )
    }
}
