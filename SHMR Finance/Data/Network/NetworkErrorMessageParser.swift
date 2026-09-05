//
//  NetworkErrorMessageParser.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

private nonisolated enum Constants {
    static let messageKeys = [
        "detail",
        "message",
        "error",
        "msg"
    ]
    static let messagesSeparator = "; "
}

nonisolated enum NetworkErrorMessageParser {
    static func message(from data: Data) -> String? {
        guard !data.isEmpty else {
            return nil
        }

        if let json = try? JSONSerialization.jsonObject(with: data) {
            return message(from: json)
        }

        return normalizedString(String(data: data, encoding: .utf8))
    }

    private static func message(
        from json: Any
    ) -> String? {
        if let string = json as? String {
            return normalizedString(string)
        }

        if let dictionary = json as? [String: Any] {
            for key in Constants.messageKeys {
                guard let value = dictionary[key],
                      let message = message(from: value) else {
                    continue
                }

                return message
            }

            return nil
        }

        if let array = json as? [Any] {
            let messages = array.compactMap {
                message(from: $0)
            }

            guard !messages.isEmpty else {
                return nil
            }

            return messages.joined(
                separator: Constants.messagesSeparator
            )
        }

        return nil
    }

    private static func normalizedString(
        _ value: String?
    ) -> String? {
        guard
            let value,
            !value.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
        else {
            return nil
        }

        return value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }
}
