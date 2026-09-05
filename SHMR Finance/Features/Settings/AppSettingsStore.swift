//
//  AppSettingsStore.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 05.08.2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class AppSettingsStore {
    private enum Keys {
        static let theme = "appTheme"
        static let tint = "appTint"
        static let language = "appLanguage"
        static let biometricUnlock = "isBiometricUnlockEnabled"
        static let biometricDomainState = "biometricDomainState"
    }

    var theme: AppTheme {
        didSet {
            userDefaults.set(theme.rawValue, forKey: Keys.theme)
        }
    }

    var tint: AppTint {
        didSet {
            userDefaults.set(tint.rawValue, forKey: Keys.tint)
        }
    }

    var language: AppLanguage {
        didSet {
            userDefaults.set(language.rawValue, forKey: Keys.language)
            AppLocalization.configure(language: language)
        }
    }

    private(set) var isBiometricUnlockEnabled: Bool

    private let userDefaults: UserDefaults
    private var biometricDomainState: Data?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        theme = userDefaults.string(forKey: Keys.theme)
            .flatMap(AppTheme.init(rawValue:))
            ?? .system
        tint = userDefaults.string(forKey: Keys.tint)
            .flatMap(AppTint.init(rawValue:))
            ?? .blue
        language = userDefaults.string(forKey: Keys.language)
            .flatMap(AppLanguage.init(rawValue:))
            ?? .systemDefault
        isBiometricUnlockEnabled = userDefaults.bool(
            forKey: Keys.biometricUnlock
        )
        biometricDomainState = userDefaults.data(
            forKey: Keys.biometricDomainState
        )
        AppLocalization.configure(language: language)
    }

    func enableBiometricUnlock(domainState: Data) {
        isBiometricUnlockEnabled = true
        biometricDomainState = domainState
        userDefaults.set(true, forKey: Keys.biometricUnlock)
        userDefaults.set(domainState, forKey: Keys.biometricDomainState)
    }

    func disableBiometricUnlock() {
        isBiometricUnlockEnabled = false
        biometricDomainState = nil
        userDefaults.set(false, forKey: Keys.biometricUnlock)
        userDefaults.removeObject(forKey: Keys.biometricDomainState)
    }

    func validateBiometricDomainState(
        _ currentDomainState: Data?
    ) -> Bool {
        guard isBiometricUnlockEnabled else {
            return false
        }

        guard let biometricDomainState else {
            disableBiometricUnlock()
            return false
        }

        guard let currentDomainState else {
            return false
        }

        guard biometricDomainState == currentDomainState else {
            disableBiometricUnlock()
            return false
        }

        return true
    }
}
