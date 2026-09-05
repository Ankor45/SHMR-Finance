//
//  APIConfiguration.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

nonisolated struct APIConfiguration: Sendable {
    // MARK: - Public Properties

    let baseURL: URL
    let token: String

    // MARK: - Initializers

    init(bundle: Bundle = .main) throws {
        guard
            let baseURLString = bundle.object(
                forInfoDictionaryKey: "APIBaseURL"
            ) as? String,
            let baseURL = URL(string: baseURLString),
            baseURL.scheme == "https"
        else {
            throw APIConfigurationError.invalidBaseURL
        }

        guard
            let token = bundle.object(
                forInfoDictionaryKey: "APIToken"
            ) as? String,
            !token.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
        else {
            throw APIConfigurationError.missingToken
        }

        self.baseURL = baseURL
        self.token = token
    }
}

nonisolated enum APIConfigurationError: LocalizedError {
    case invalidBaseURL
    case missingToken

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            AppLocalization.string(
                localized: "В конфигурации отсутствует корректный HTTPS APIBaseURL."
            )
        case .missingToken:
            AppLocalization.string(
                localized: "Добавьте Bearer-токен в Secrets.xcconfig."
            )
        }
    }
}
