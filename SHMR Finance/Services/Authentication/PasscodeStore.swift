//
//  PasscodeStore.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 05.08.2026.
//

import Foundation
import Observation

private enum Constants {
    static let installationMarker = "hasInitializedPasscodeStorage"

    enum Lockout {
        static let attemptsBeforeFirstDelay = 4
        static let firstDelay: TimeInterval = 30
        static let secondDelay: TimeInterval = 60
        static let thirdDelay: TimeInterval = 5 * 60
        static let fourthDelay: TimeInterval = 15 * 60
        static let maximumDelay: TimeInterval = 60 * 60
    }

    enum ASCIIDigit {
        static let first: UInt8 = 48
        static let last: UInt8 = 57
    }
}

enum PasscodeAvailability: Equatable {
    case notConfigured
    case configured
    case unavailable
}

enum PasscodeVerificationResult {
    case success
    case incorrect
    case locked
}

enum PasscodeStoreError: LocalizedError {
    case invalidPasscode
    case passcodeNotConfigured
    case storageUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidPasscode:
            AppLocalization.string(
                localized: "ПИН-код должен состоять из четырёх цифр."
            )
        case .passcodeNotConfigured:
            AppLocalization.string(localized: "ПИН-код не установлен.")
        case .storageUnavailable:
            AppLocalization.string(
                localized: "Не удалось обратиться к защищённому хранилищу."
            )
        }
    }
}

@MainActor
@Observable
final class PasscodeStore {
    // MARK: - Public Properties

    static let passcodeLength = 4

    private(set) var availability = PasscodeAvailability.unavailable
    private(set) var lockoutDeadline: ContinuousClock.Instant?

    // MARK: - Private Properties

    private let storage: PasscodeStorage
    private var attemptState = PasscodeAttemptState.empty

    // MARK: - Initializers

    init(
        storage: PasscodeStorage = PasscodeStorage(),
        userDefaults: UserDefaults = .standard
    ) {
        self.storage = storage

        guard userDefaults.bool(
            forKey: Constants.installationMarker
        ) else {
            do {
                try storage.removeAllData()
                userDefaults.set(
                    true,
                    forKey: Constants.installationMarker
                )
                refresh()
            } catch {
                availability = .unavailable
            }
            return
        }

        refresh()
    }

    // MARK: - Public Methods

    func refresh() {
        do {
            let passcode = try storage.loadPasscode()
            let attemptState = try storage.loadAttemptState()

            if let passcode, !Self.isValid(passcode) {
                throw PasscodeStorageError.invalidData
            }

            self.attemptState = attemptState
            lockoutDeadline = Self.restoredLockoutDeadline(
                from: attemptState
            )
            availability = passcode == nil
                ? .notConfigured
                : .configured
        } catch {
            availability = .unavailable
            lockoutDeadline = nil
        }
    }

    func setPasscode(_ passcode: String) throws {
        guard Self.isValid(passcode) else {
            throw PasscodeStoreError.invalidPasscode
        }

        do {
            try storage.saveAttemptState(.empty)
            try storage.savePasscode(passcode)
        } catch {
            throw PasscodeStoreError.storageUnavailable
        }

        attemptState = .empty
        lockoutDeadline = nil
        availability = .configured
    }

    func resetPasscode() throws {
        do {
            try storage.removeAllData()
        } catch {
            throw PasscodeStoreError.storageUnavailable
        }

        attemptState = .empty
        lockoutDeadline = nil
        availability = .notConfigured
    }

    func verify(_ candidate: String) throws -> PasscodeVerificationResult {
        guard Self.isValid(candidate) else {
            throw PasscodeStoreError.invalidPasscode
        }

        if isLocked {
            return .locked
        }

        let storedPasscode: String

        do {
            guard let passcode = try storage.loadPasscode() else {
                throw PasscodeStoreError.passcodeNotConfigured
            }
            storedPasscode = passcode
        } catch let error as PasscodeStoreError {
            throw error
        } catch {
            throw PasscodeStoreError.storageUnavailable
        }

        guard Self.isValid(storedPasscode) else {
            throw PasscodeStoreError.storageUnavailable
        }

        if Self.matches(candidate, storedPasscode) {
            try resetAttempts()
            return .success
        }

        return try registerFailedAttempt()
    }

    func remainingLockoutSeconds(
        at instant: ContinuousClock.Instant = .now
    ) -> Int? {
        guard
            let lockoutDeadline,
            instant < lockoutDeadline
        else {
            return nil
        }

        let components = instant
            .duration(to: lockoutDeadline)
            .components
        let roundedSeconds = components.seconds
            + (components.attoseconds > .zero ? 1 : 0)

        return Int(roundedSeconds)
    }

    // MARK: - Private Methods

    private func resetAttempts() throws {
        do {
            try storage.saveAttemptState(.empty)
        } catch {
            throw PasscodeStoreError.storageUnavailable
        }

        attemptState = .empty
        lockoutDeadline = nil
    }

    private var isLocked: Bool {
        guard let lockoutDeadline else {
            return false
        }

        return ContinuousClock.now < lockoutDeadline
    }

    private func registerFailedAttempt() throws -> PasscodeVerificationResult {
        var updatedState = attemptState
        updatedState.failedAttempts += 1
        let newLockoutDeadline: ContinuousClock.Instant?

        if let duration = Self.lockoutDuration(
            after: updatedState.failedAttempts
        ) {
            updatedState.lockoutUntil = Date.now.addingTimeInterval(
                duration
            )
            updatedState.lockoutStartedAtUptime =
                ProcessInfo.processInfo.systemUptime
            updatedState.lockoutDuration = duration
            newLockoutDeadline = ContinuousClock.now.advanced(
                by: .seconds(duration)
            )
        } else {
            updatedState.lockoutUntil = nil
            updatedState.lockoutStartedAtUptime = nil
            updatedState.lockoutDuration = nil
            newLockoutDeadline = nil
        }

        do {
            try storage.saveAttemptState(updatedState)
        } catch {
            throw PasscodeStoreError.storageUnavailable
        }

        attemptState = updatedState
        lockoutDeadline = newLockoutDeadline

        if newLockoutDeadline != nil {
            return .locked
        }

        return .incorrect
    }

    private static func lockoutDuration(
        after failedAttempts: Int
    ) -> TimeInterval? {
        switch failedAttempts {
        case ...Constants.Lockout.attemptsBeforeFirstDelay:
            nil
        case Constants.Lockout.attemptsBeforeFirstDelay + 1:
            Constants.Lockout.firstDelay
        case Constants.Lockout.attemptsBeforeFirstDelay + 2:
            Constants.Lockout.secondDelay
        case Constants.Lockout.attemptsBeforeFirstDelay + 3:
            Constants.Lockout.thirdDelay
        case Constants.Lockout.attemptsBeforeFirstDelay + 4:
            Constants.Lockout.fourthDelay
        default:
            Constants.Lockout.maximumDelay
        }
    }

    private static func restoredLockoutDeadline(
        from state: PasscodeAttemptState,
        date: Date = .now,
        systemUptime: TimeInterval = ProcessInfo.processInfo.systemUptime,
        instant: ContinuousClock.Instant = .now
    ) -> ContinuousClock.Instant? {
        let remainingDuration: TimeInterval?

        if let startedAtUptime = state.lockoutStartedAtUptime,
           let duration = state.lockoutDuration,
           systemUptime >= startedAtUptime {
            remainingDuration = duration
                - (systemUptime - startedAtUptime)
        } else if let lockoutUntil = state.lockoutUntil {
            remainingDuration = lockoutUntil.timeIntervalSince(date)
        } else {
            remainingDuration = nil
        }

        guard let remainingDuration, remainingDuration > .zero else {
            return nil
        }

        return instant.advanced(by: .seconds(remainingDuration))
    }

    private static func isValid(_ passcode: String) -> Bool {
        let bytes = Array(passcode.utf8)
        let digitRange = Constants.ASCIIDigit.first...Constants.ASCIIDigit.last

        return bytes.count == passcodeLength
            && bytes.allSatisfy(digitRange.contains)
    }

    private static func matches(
        _ candidate: String,
        _ storedPasscode: String
    ) -> Bool {
        let candidateBytes = Array(candidate.utf8)
        let storedBytes = Array(storedPasscode.utf8)

        guard candidateBytes.count == storedBytes.count else {
            return false
        }

        var difference: UInt8 = .zero

        for (candidateByte, storedByte) in zip(
            candidateBytes,
            storedBytes
        ) {
            difference |= candidateByte ^ storedByte
        }

        return difference == .zero
    }
}
