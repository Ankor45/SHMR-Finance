//
//  TransactionEditorAmountView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import SwiftUI

private enum Constants {
    static let dividerSpacing: CGFloat = 14
}

struct TransactionEditorAmountView: View {
    // MARK: - Properties

    let amountText: String
    let currencyCode: String
    let isActive: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    let onPaste: (String) -> Void

    // MARK: - View Body

    var body: some View {
        BalanceAmountInputView(
            amountText: amountText,
            currencySymbol: displayedCurrency,
            isCurrencyVisible: true,
            isActive: isActive,
            isCursorAfterCurrency: true,
            isDisabled: isDisabled,
            onTap: onTap,
            onPaste: onPaste
        )
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, Constants.dividerSpacing)
    }

    // MARK: - Private Properties

    private var displayedCurrency: String {
        CurrencyPresentation.symbol(for: currencyCode)
    }
}
