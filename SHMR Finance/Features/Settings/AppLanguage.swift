//
//  AppLanguage.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 06.08.2026.
//

import Foundation

nonisolated enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case russian = "ru"
    case english = "en"

    var id: Self { self }

    var locale: Locale {
        switch self {
        case .russian:
            Locale(identifier: "ru_RU")
        case .english:
            Locale(identifier: "en_GB")
        }
    }

    var nativeName: String {
        switch self {
        case .russian:
            "Русский"
        case .english:
            "English"
        }
    }

    var displayTitle: String {
        switch self {
        case .russian:
            "🇷🇺  \(nativeName)"
        case .english:
            "🇬🇧  \(nativeName)"
        }
    }

    static var systemDefault: AppLanguage {
        let languageCode = Locale.preferredLanguages.first?
            .replacingOccurrences(of: "_", with: "-")
            .split(separator: "-")
            .first?
            .lowercased()

        return languageCode == AppLanguage.russian.rawValue
            ? .russian
            : .english
    }
}
