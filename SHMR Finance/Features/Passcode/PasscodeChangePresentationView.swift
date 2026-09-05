//
//  PasscodeChangePresentationView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 05.08.2026.
//

import SwiftUI

private enum BiometricSetupAlert: Identifiable {
    case offer(BiometricType)
    case retry(String)

    var id: Int {
        switch self {
        case .offer:
            0
        case .retry:
            1
        }
    }
}

private enum Constants {
    static let preferredHeightFraction = 0.57
    static let minimumHeight: CGFloat = 480
    static let maximumHeight: CGFloat = 510
    static var connectTitle: String {
        AppLocalization.string(localized: "Подключить")
    }
    static var notNowTitle: String {
        AppLocalization.string(localized: "Не сейчас")
    }
    static var retryTitle: String {
        AppLocalization.string(localized: "Попробовать снова")
    }
    static var skipTitle: String {
        AppLocalization.string(
            localized: "Продолжить без биометрии"
        )
    }
    static var failureTitle: String {
        AppLocalization.string(
            localized: "Не удалось выполнить вход"
        )
    }
    static var failureMessage: String {
        AppLocalization.string(
            localized: "Попробуйте распознавание ещё раз или продолжите без биометрии."
        )
    }
    static var lockedOutMessage: String {
        AppLocalization.string(
            localized: "Биометрия временно заблокирована. Продолжите с ПИН-кодом."
        )
    }
    static var unavailableMessage: String {
        AppLocalization.string(
            localized: "Биометрическая авторизация сейчас недоступна. Продолжите с ПИН-кодом."
        )
    }
}

struct PasscodeChangePresentationView: View {
    // MARK: - Properties

    @Environment(AppSettingsStore.self) private var settingsStore
    @Environment(HapticsService.self) private var hapticsService
    @Environment(BiometricAuthenticationService.self)
    private var biometricService

    let store: PasscodeStore
    let mode: PasscodeMode
    let title: String
    let onDismiss: () -> Void
    let onCompletion: () -> Void

    // MARK: - State

    @State private var biometricAlert: BiometricSetupAlert?
    @State private var isCompletingSetup = false

    // MARK: - View Body

    var body: some View {
        SettingsBottomPanelPresentationView(
            preferredHeightFraction:
                Constants.preferredHeightFraction,
            minimumHeight: Constants.minimumHeight,
            maximumHeight: Constants.maximumHeight,
            onDismiss: onDismiss
        ) {
            PasscodeView(
                mode: mode,
                store: store,
                panelTitle: title,
                onCompletion: handlePasscodeCompletion
            )
            .allowsHitTesting(!isCompletingSetup)
        }
        .alert(item: $biometricAlert) { alert in
            biometricAlertContent(for: alert)
        }
        .onDisappear {
            biometricService.cancelAuthentication()
        }
    }

    // MARK: - Private Methods

    private func handlePasscodeCompletion() {
        guard mode == .setup else {
            onCompletion()
            return
        }

        isCompletingSetup = true
        settingsStore.disableBiometricUnlock()
        biometricService.refreshAvailability()

        guard
            biometricService.isAvailable,
            let type = biometricService.type
        else {
            onCompletion()
            return
        }

        biometricAlert = .offer(type)
    }

    private func biometricAlertContent(
        for alert: BiometricSetupAlert
    ) -> Alert {
        switch alert {
        case .offer(let type):
            Alert(
                title: Text(type.title),
                message: Text(type.usageDescription),
                primaryButton: .default(Text(Constants.connectTitle)) {
                    authenticateWithBiometrics()
                },
                secondaryButton: .cancel(Text(Constants.notNowTitle)) {
                    finishWithoutBiometrics()
                }
            )

        case .retry(let message):
            Alert(
                title: Text(Constants.failureTitle),
                message: Text(message),
                primaryButton: .default(Text(Constants.retryTitle)) {
                    authenticateWithBiometrics()
                },
                secondaryButton: .cancel(Text(Constants.skipTitle)) {
                    finishWithoutBiometrics()
                }
            )
        }
    }

    private func authenticateWithBiometrics() {
        Task {
            let result = await biometricService.authenticate()
            handleAuthenticationResult(result)
        }
    }

    private func handleAuthenticationResult(
        _ result: BiometricAuthenticationResult
    ) {
        switch result {
        case .success:
            guard let domainState = biometricService.currentDomainState else {
                biometricAlert = .retry(Constants.unavailableMessage)
                return
            }

            settingsStore.enableBiometricUnlock(
                domainState: domainState
            )
            hapticsService.successOccurred()
            onCompletion()

        case .cancelled, .fallbackRequested, .failed:
            biometricAlert = .retry(Constants.failureMessage)
        case .lockedOut:
            biometricAlert = .retry(Constants.lockedOutMessage)
        case .unavailable:
            biometricAlert = .retry(Constants.unavailableMessage)
        }
    }

    private func finishWithoutBiometrics() {
        settingsStore.disableBiometricUnlock()
        onCompletion()
    }
}
