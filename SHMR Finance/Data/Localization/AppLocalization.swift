//
//  AppLocalization.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 06.08.2026.
//

import Foundation

nonisolated enum AppLocalization {
    private static let state = AppLocalizationState(
        initialLanguage: .systemDefault
    )

    static var locale: Locale {
        state.currentLanguage.locale
    }

    static func configure(language: AppLanguage) {
        state.setLanguage(language)
    }

    static func string(localized key: String) -> String {
        state.localizedString(forKey: key)
    }
}

private nonisolated final class AppLocalizationState: @unchecked Sendable {
    private let lock = NSLock()
    private let bundles: [AppLanguage: Bundle]
    private var language: AppLanguage

    init(initialLanguage: AppLanguage) {
        language = initialLanguage
        bundles = Dictionary(
            uniqueKeysWithValues: AppLanguage.allCases.compactMap {
                language in
                guard let path = Bundle.main.path(
                    forResource: language.rawValue,
                    ofType: "lproj"
                ), let bundle = Bundle(path: path) else {
                    return nil
                }

                return (language, bundle)
            }
        )
    }

    var currentLanguage: AppLanguage {
        lock.withLock { language }
    }

    func setLanguage(_ language: AppLanguage) {
        lock.withLock {
            self.language = language
        }
    }

    func localizedString(forKey key: String) -> String {
        let language = currentLanguage

        guard language != .russian else {
            return key
        }

        let bundle = bundles[language] ?? .main

        return bundle.localizedString(
            forKey: key,
            value: key,
            table: nil
        )
    }
}
