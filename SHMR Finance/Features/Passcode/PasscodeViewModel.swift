//
//  PasscodeViewModel.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 05.08.2026.
//

import Foundation
import Observation

private enum Constants {
    static let minimumDigit = 0
    static let maximumDigit = 9
    static var unlockTitle: String {
        AppLocalization.string(
            localized: "Введите ПИН-код"
        )
    }
    static var currentPasscodeTitle: String {
        AppLocalization.string(
            localized: "Введите старый ПИН-код"
        )
    }
    static var newPasscodeTitle: String {
        AppLocalization.string(
            localized: "Введите новый ПИН-код"
        )
    }
    static var confirmationTitle: String {
        AppLocalization.string(
            localized: "Повторите ПИН-код"
        )
    }
    static var incorrectPasscodeMessage: String {
        AppLocalization.string(
            localized: "Неверный ПИН-код."
        )
    }
    static var mismatchMessage: String {
        AppLocalization.string(
            localized: "ПИН-коды не совпадают. Введите новый ПИН-код ещё раз."
        )
    }
}

private enum PasscodeStage {
    case verifyCurrent
    case enterNew
    case confirmNew
}

enum PasscodeInputResult {
    case inProgress
    case completed
}

@MainActor
@Observable
final class PasscodeViewModel {
    // MARK: - Public Properties

    private(set) var enteredPasscode = String()
    private(set) var errorMessage: String?

    var title: String {
        switch stage {
        case .verifyCurrent:
            mode == .unlock || mode == .verify
                ? Constants.unlockTitle
                : Constants.currentPasscodeTitle
        case .enterNew:
            Constants.newPasscodeTitle
        case .confirmNew:
            Constants.confirmationTitle
        }
    }

    // MARK: - Private Properties

    private let mode: PasscodeMode
    private let store: PasscodeStore
    private var stage: PasscodeStage
    private var pendingPasscode: String?

    // MARK: - Initializers

    init(
        mode: PasscodeMode,
        store: PasscodeStore
    ) {
        self.mode = mode
        self.store = store

        switch mode {
        case .setup:
            stage = .enterNew
        case .unlock, .verify, .change:
            stage = .verifyCurrent
        }
    }

    // MARK: - Public Methods

    func appendDigit(_ digit: Int) -> PasscodeInputResult {
        guard
            (Constants.minimumDigit...Constants.maximumDigit).contains(digit),
            enteredPasscode.count < PasscodeStore.passcodeLength
        else {
            return .inProgress
        }

        errorMessage = nil
        enteredPasscode.append(String(digit))

        guard enteredPasscode.count == PasscodeStore.passcodeLength else {
            return .inProgress
        }

        return submitEnteredPasscode()
    }

    func deleteLastDigit() {
        guard !enteredPasscode.isEmpty else {
            return
        }

        errorMessage = nil
        enteredPasscode.removeLast()
    }

    // MARK: - Private Methods

    private func submitEnteredPasscode() -> PasscodeInputResult {
        let passcode = enteredPasscode
        enteredPasscode = String()

        switch stage {
        case .verifyCurrent:
            return verifyCurrentPasscode(passcode)
        case .enterNew:
            pendingPasscode = passcode
            stage = .confirmNew
            return .inProgress
        case .confirmNew:
            return confirmNewPasscode(passcode)
        }
    }

    private func verifyCurrentPasscode(
        _ passcode: String
    ) -> PasscodeInputResult {
        do {
            switch try store.verify(passcode) {
            case .success:
                if mode == .unlock || mode == .verify {
                    return .completed
                }

                stage = .enterNew
                return .inProgress

            case .incorrect:
                errorMessage = Constants.incorrectPasscodeMessage
                return .inProgress

            case .locked:
                return .inProgress
            }
        } catch {
            errorMessage = error.localizedDescription
            return .inProgress
        }
    }

    private func confirmNewPasscode(
        _ passcode: String
    ) -> PasscodeInputResult {
        guard passcode == pendingPasscode else {
            pendingPasscode = nil
            stage = .enterNew
            errorMessage = Constants.mismatchMessage
            return .inProgress
        }

        do {
            try store.setPasscode(passcode)
            pendingPasscode = nil
            return .completed
        } catch {
            errorMessage = error.localizedDescription
            return .inProgress
        }
    }
}
