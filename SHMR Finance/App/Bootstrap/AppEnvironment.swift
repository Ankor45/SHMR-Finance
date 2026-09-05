//
//  AppEnvironment.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 04.09.2026.
//

import Foundation

private nonisolated enum Constants {
    static let infoDictionaryKey = "AppEnvironment"
}

nonisolated enum AppEnvironment: String, Sendable {
    case demo
    case live

    init(bundle: Bundle = .main) throws {
        guard let value = bundle.object(
            forInfoDictionaryKey: Constants.infoDictionaryKey
        ) as? String else {
            throw AppEnvironmentError.missingValue
        }
        let normalizedValue = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard let environment = AppEnvironment(
            rawValue: normalizedValue
        ) else {
            throw AppEnvironmentError.unsupportedValue(value)
        }

        self = environment
    }

    var storageScope: LocalStorageScope {
        switch self {
        case .demo:
            .demo
        case .live:
            .live
        }
    }
}

nonisolated enum AppEnvironmentError: LocalizedError, Sendable {
    case missingValue
    case unsupportedValue(String)

    var errorDescription: String? {
        switch self {
        case .missingValue:
            AppLocalization.string(
                localized: "В конфигурации отсутствует AppEnvironment."
            )
        case let .unsupportedValue(value):
            String(
                format: AppLocalization.string(
                    localized: "Неизвестное окружение приложения: %@."
                ),
                value
            )
        }
    }
}
