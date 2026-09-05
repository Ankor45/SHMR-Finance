//
//  DemoFinanceDataProviderError.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 04.09.2026.
//

import Foundation

nonisolated enum DemoFinanceDataProviderError: LocalizedError, Sendable {
    case seedNotFound
    case invalidSeed
    case transactionNotFound(id: Int)

    var errorDescription: String? {
        switch self {
        case .seedNotFound:
            AppLocalization.string(
                localized: "Не найдены начальные данные деморежима."
            )
        case .invalidSeed:
            AppLocalization.string(
                localized: "Начальные данные деморежима повреждены."
            )
        case .transactionNotFound(let id):
            String(
                format: AppLocalization.string(
                    localized: "Операция с идентификатором %lld не найдена"
                ),
                Int64(id)
            )
        }
    }
}
