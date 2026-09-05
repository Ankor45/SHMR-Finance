//
//  AmountInputState.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation
import Observation

private enum Constants {
    static let zero = "0"
    static let maximumIntegerDigits = 15
    static let maximumFractionDigits = 2
    static let parsingLocale = AppLocale.posix
}

@MainActor
@Observable
final class AmountInputState {
    // MARK: - Public Properties

    static let storageDecimalSeparator = "."

    private(set) var text: String
    private(set) var hasStartedEditing = false

    var decimalValue: Decimal? {
        let normalizedText = text.hasSuffix(
            Self.storageDecimalSeparator
        )
            ? String(text.dropLast())
            : text

        guard !normalizedText.isEmpty else {
            return nil
        }

        return Decimal(
            string: normalizedText,
            locale: Constants.parsingLocale
        )
    }

    var amount: Decimal {
        decimalValue ?? .zero
    }

    // MARK: - Initializers

    init(initialAmount: Decimal?) {
        if let initialAmount {
            text = NSDecimalNumber(
                decimal: initialAmount
            ).stringValue
        } else {
            text = String()
        }
    }

    // MARK: - Public Methods

    func appendDigit(_ digit: Int) {
        guard (0...9).contains(digit) else {
            return
        }

        if !hasStartedEditing {
            text = String(digit)
            hasStartedEditing = true
            return
        }

        if let separatorIndex = text.firstIndex(
            of: Character(Self.storageDecimalSeparator)
        ) {
            let fractionStart = text.index(after: separatorIndex)
            let fractionDigits = text[fractionStart...].count

            guard fractionDigits < Constants.maximumFractionDigits else {
                return
            }
        } else {
            let integerDigits = text.filter(\.isNumber).count

            guard integerDigits < Constants.maximumIntegerDigits else {
                return
            }
        }

        if text == Constants.zero {
            text = String(digit)
        } else {
            text.append(String(digit))
        }
    }

    func appendDecimalSeparator() {
        guard !text.contains(Self.storageDecimalSeparator) else {
            return
        }

        if !hasStartedEditing {
            text =
                Constants.zero
                + Self.storageDecimalSeparator
            hasStartedEditing = true
            return
        }

        if text.isEmpty {
            text = Constants.zero
        }

        text.append(Self.storageDecimalSeparator)
    }

    func deleteLastCharacter() {
        guard !text.isEmpty else {
            return
        }

        hasStartedEditing = true
        text.removeLast()
    }

    @discardableResult
    func paste(_ pastedText: String) -> Bool {
        let significantCharacters = pastedText.compactMap {
            character -> Character? in
            if character.isNumber {
                return character
            }

            return isDecimalSeparator(character)
                ? character
                : nil
        }

        guard
            significantCharacters.contains(where: \.isNumber)
        else {
            return false
        }

        guard let separatorIndex = significantCharacters.lastIndex(
            where: isDecimalSeparator
        ) else {
            text = limitedInteger(from: significantCharacters)
            hasStartedEditing = true
            return true
        }

        let integerCharacters = significantCharacters[..<separatorIndex]
        let integerDigits = digits(from: integerCharacters)
        let limitedInteger = String(
            integerDigits.prefix(Constants.maximumIntegerDigits)
        )
        let normalizedInteger = limitedInteger.isEmpty
            ? Constants.zero
            : limitedInteger

        let fractionStart = significantCharacters.index(
            after: separatorIndex
        )
        let fractionDigits = String(
            digits(
                from: significantCharacters[fractionStart...]
            )
            .prefix(Constants.maximumFractionDigits)
        )

        text =
            normalizedInteger
            + Self.storageDecimalSeparator
            + fractionDigits
        hasStartedEditing = true
        return true
    }

    // MARK: - Private Methods

    private func limitedInteger<C: Collection>(
        from characters: C
    ) -> String where C.Element == Character {
        String(
            digits(from: characters)
                .prefix(Constants.maximumIntegerDigits)
        )
    }

    private func digits<C: Collection>(
        from characters: C
    ) -> String where C.Element == Character {
        characters.reduce(into: String()) { result, character in
            guard let digit = character.wholeNumberValue else {
                return
            }

            result.append(String(digit))
        }
    }

    private func isDecimalSeparator(
        _ character: Character
    ) -> Bool {
        character == "." || character == ","
    }
}
