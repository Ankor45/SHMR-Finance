//
//  CurrencyPresentation.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation

nonisolated enum CurrencyPresentation {
    static let defaultCode = "RUB"
    static let defaultFractionDigits = 0...2

    static func symbol(for code: String) -> String {
        code == defaultCode ? "₽" : code
    }

    static func formattedAmount(
        _ amount: Decimal,
        currencyCode: String,
        fractionDigits: ClosedRange<Int> = defaultFractionDigits
    ) -> String {
        if currencyCode == defaultCode {
            let formattedAmount = amount.formatted(
                .number
                    .precision(.fractionLength(fractionDigits))
                    .locale(AppLocalization.locale)
            )
            return "\(formattedAmount) \(symbol(for: currencyCode))"
        }

        return amount.formatted(
            .currency(code: currencyCode)
                .precision(.fractionLength(fractionDigits))
                .locale(AppLocalization.locale)
        )
    }
}
