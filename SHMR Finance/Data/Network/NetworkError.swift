//
//  NetworkError.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

nonisolated enum NetworkError: Error {
    case invalidURL
    case requestEncoding(Error)
    case transport(URLError)
    case invalidResponse
    case httpStatus(code: Int, message: String?)
    case emptyResponse
    case responseDecoding(Error)
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            AppLocalization.string(localized: "Не удалось сформировать адрес запроса.")

        case let .requestEncoding(error):
            String(
                format: AppLocalization.string(
                    localized: "Не удалось подготовить данные запроса: %@"
                ),
                error.localizedDescription
            )

        case let .transport(error):
            String(
                format: AppLocalization.string(localized: "Ошибка соединения: %@"),
                error.localizedDescription
            )

        case .invalidResponse:
            AppLocalization.string(localized: "Сервер вернул некорректный ответ.")

        case let .httpStatus(code, message):
            if let message {
                String(
                    format: AppLocalization.string(
                        localized: "Сервер вернул ошибку %1$lld: %2$@"
                    ),
                    Int64(code),
                    message
                )
            } else {
                String(
                    format: AppLocalization.string(
                        localized: "Сервер вернул ошибку %lld."
                    ),
                    Int64(code)
                )
            }

        case .emptyResponse:
            AppLocalization.string(localized: "Сервер вернул пустой ответ.")

        case let .responseDecoding(error):
            String(
                format: AppLocalization.string(
                    localized: "Не удалось обработать ответ сервера: %@"
                ),
                error.localizedDescription
            )
        }
    }
}

extension NetworkError {
    var allowsLocalFallback: Bool {
        switch self {
        case .transport,
             .invalidResponse,
             .emptyResponse,
             .responseDecoding:
            true

        case let .httpStatus(code, _):
            code == 408
                || code == 429
                || (500...599).contains(code)

        case .invalidURL,
             .requestEncoding:
            false
        }
    }

    var isNotFound: Bool {
        guard case .httpStatus(code: 404, message: _) = self else {
            return false
        }

        return true
    }

    var allowsIdempotentMutationDeferral: Bool {
        allowsLocalFallback
    }

    var allowsSafeCreationDeferral: Bool {
        guard case .transport(let error) = self else {
            return false
        }

        return switch error.code {
        case .notConnectedToInternet,
             .cannotFindHost,
             .cannotConnectToHost,
             .dnsLookupFailed,
             .internationalRoamingOff,
             .dataNotAllowed:
            true
        default:
            false
        }
    }

    var isPermanentClientError: Bool {
        guard case .httpStatus(let code, _) = self else {
            return false
        }

        return (400...499).contains(code)
            && code != 408
            && code != 429
    }
}
