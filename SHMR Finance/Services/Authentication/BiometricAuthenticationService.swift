//
//  BiometricAuthenticationService.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 06.08.2026.
//

import LocalAuthentication
import Observation

enum BiometricType: Hashable {
    case faceID
    case touchID
}

enum BiometricAuthenticationResult {
    case success
    case cancelled
    case fallbackRequested
    case failed
    case lockedOut
    case unavailable
}

@MainActor
@Observable
final class BiometricAuthenticationService {
    // MARK: - Public Properties

    private(set) var type: BiometricType?
    private(set) var isAvailable = false
    private(set) var isAuthenticating = false
    private(set) var currentDomainState: Data?

    // MARK: - Private Properties

    private var activeContext: LAContext?

    // MARK: - Initializers

    init() {
        refreshAvailability()
    }

    // MARK: - Public Methods

    func refreshAvailability() {
        let context = LAContext()
        isAvailable = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: nil
        )
        type = Self.biometricType(from: context.biometryType)
        currentDomainState = context.domainState.biometry.stateHash
    }

    func authenticate() async -> BiometricAuthenticationResult {
        guard !isAuthenticating else {
            return .cancelled
        }

        let context = LAContext()
        context.localizedFallbackTitle = AppLocalization.string(
            localized: "Ввести ПИН-код"
        )
        var availabilityError: NSError?

        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &availabilityError
        ) else {
            refreshAvailability()
            guard let availabilityError else {
                return .unavailable
            }

            return Self.result(from: availabilityError)
        }

        isAuthenticating = true
        activeContext = context
        await Task.yield()

        defer {
            if activeContext === context {
                activeContext = nil
                isAuthenticating = false
            }
            refreshAvailability()
        }

        do {
            let isAuthenticated = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: AppLocalization.string(
                    localized: "Войдите в приложение"
                )
            )

            return isAuthenticated ? .success : .failed
        } catch {
            return Self.result(from: error)
        }
    }

    func cancelAuthentication() {
        activeContext?.invalidate()
        activeContext = nil
        isAuthenticating = false
    }

    // MARK: - Private Methods

    private static func biometricType(
        from systemType: LABiometryType
    ) -> BiometricType? {
        switch systemType {
        case .faceID:
            .faceID
        case .touchID:
            .touchID
        case .none, .opticID:
            nil
        @unknown default:
            nil
        }
    }

    private static func result(
        from error: Error
    ) -> BiometricAuthenticationResult {
        guard let error = error as? LAError else {
            return .failed
        }

        switch error.code {
        case .userCancel,
             .appCancel,
             .systemCancel:
            return .cancelled
        case .userFallback:
            return .fallbackRequested
        case .biometryLockout:
            return .lockedOut
        case .biometryNotAvailable,
             .biometryNotEnrolled,
             .passcodeNotSet:
            return .unavailable
        default:
            return .failed
        }
    }
}
