//
//  NormalizedSearchText.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import Foundation

private enum Constants {
    static var locale: Locale { AppLocalization.locale }
}

struct NormalizedSearchText {
    let characters: [Character]
    let words: [[Character]]

    init(_ source: String) {
        let normalized = source
            .folding(
                options: [
                    .caseInsensitive,
                    .diacriticInsensitive,
                    .widthInsensitive
                ],
                locale: Constants.locale
            )
            .lowercased(with: Constants.locale)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")

        characters = Array(normalized)
        words = normalized
            .split(separator: " ")
            .map(Array.init)
    }
}
