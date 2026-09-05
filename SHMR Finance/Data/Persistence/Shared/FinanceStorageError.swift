//
//  FinanceStorageError.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation

nonisolated enum FinanceStorageError: LocalizedError, Sendable {
    case accountNotFound(id: Int)
    case invalidStoredTransaction(id: Int)
    case invalidStoredAccount(id: Int)
    case invalidStoredCategory(id: Int)
    case invalidPendingTransaction(id: Int)
    case invalidPendingAccount(id: Int)
    case coreDataEntityNotFound(String)

    var errorDescription: String? {
        switch self {
        case .accountNotFound(let id):
            Self.formatted(
                AppLocalization.string(localized: "Счёт с идентификатором %lld не найден"),
                id: id
            )
        case .invalidStoredTransaction(let id):
            Self.formatted(
                AppLocalization.string(
                    localized: "Локальные данные операции %lld повреждены"
                ),
                id: id
            )
        case .invalidStoredAccount(let id):
            Self.formatted(
                AppLocalization.string(
                    localized: "Локальные данные счёта %lld повреждены"
                ),
                id: id
            )
        case .invalidStoredCategory(let id):
            Self.formatted(
                AppLocalization.string(
                    localized: "Локальные данные статьи %lld повреждены"
                ),
                id: id
            )
        case .invalidPendingTransaction(let id):
            Self.formatted(
                AppLocalization.string(
                    localized: "Локальные изменения операции %lld повреждены"
                ),
                id: id
            )
        case .invalidPendingAccount(let id):
            Self.formatted(
                AppLocalization.string(
                    localized: "Локальные изменения счёта %lld повреждены"
                ),
                id: id
            )
        case .coreDataEntityNotFound(let name):
            String(
                format: AppLocalization.string(
                    localized: "Не найдена Core Data сущность %@"
                ),
                name
            )
        }
    }

    private static func formatted(
        _ format: String,
        id: Int
    ) -> String {
        String(
            format: format,
            Int64(id)
        )
    }
}
