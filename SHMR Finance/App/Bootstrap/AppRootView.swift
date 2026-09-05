//
//  AppRootView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import SplashAnimation
import SwiftUI

private enum Constants {
    static var retryTitle: String { AppLocalization.string(localized: "Повторить") }

    enum Passcode {
        static let inactivityTimeout = Duration.seconds(10 * 60)
        static var unavailableTitle: String {
            AppLocalization.string(
                localized: "ПИН-код недоступен"
            )
        }
        static var unavailableDescription: String {
            AppLocalization.string(
                localized: "Не удалось обратиться к защищённому хранилищу."
            )
        }
        static let unavailableIcon =
            "lock.trianglebadge.exclamationmark"
    }

    enum Bootstrap {
        static var loadingTitle: String {
            AppLocalization.string(
                localized: "Подготовка данных…"
            )
        }
        static var errorTitle: String {
            AppLocalization.string(
                localized: "Ошибка запуска"
            )
        }
        static let errorIcon = "exclamationmark.triangle"
    }
}

struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var bootstrap = AppBootstrapModel()
    @State private var settingsStore = AppSettingsStore()
    @State private var hapticsService = HapticsService()
    @State private var passcodeStore = PasscodeStore()
    @State private var biometricService =
        BiometricAuthenticationService()
    @State private var isSplashCompleted = false
    @State private var isAuthenticated = false
    @State private var inactiveSince: ContinuousClock.Instant?
    @State private var isBiometricPresentationActive = false

    var body: some View {
        Group {
            if !isSplashCompleted {
                SplashAnimationView(
                    isHapticsEnabled: hapticsService.isEnabled
                ) {
                    isSplashCompleted = true
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                }
            } else {
                securedContent
            }
        }
        .environment(settingsStore)
        .environment(hapticsService)
        .environment(passcodeStore)
        .environment(biometricService)
        .preferredColorScheme(settingsStore.theme.colorScheme)
        .environment(\.locale, settingsStore.language.locale)
        .tint(settingsStore.tint.color)
        .background {
            WindowAppearanceView(
                interfaceStyle: settingsStore.theme.userInterfaceStyle,
                tintColor: settingsStore.tint.uiColor,
                isPrivacyProtectionEnabled:
                    isPrivacyProtectionEnabled
            )
            .frame(width: .zero, height: .zero)
        }
        .task {
            if passcodeStore.availability == .notConfigured {
                isAuthenticated = true
            }
            await bootstrap.start()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onChange(of: passcodeStore.availability) {
            oldAvailability,
            newAvailability in
            if oldAvailability == .notConfigured,
               newAvailability == .configured {
                isAuthenticated = true
            }
        }
        .onChange(of: biometricService.isAuthenticating) {
            _, isAuthenticating in
            if isAuthenticating {
                isBiometricPresentationActive = true
            } else if scenePhase == .active {
                isBiometricPresentationActive = false
            }
        }
    }

    @ViewBuilder
    private var securedContent: some View {
        if passcodeStore.availability == .unavailable {
            passcodeUnavailableContent
        } else if passcodeStore.availability == .configured,
                  !isAuthenticated {
            PasscodeView(
                mode: .unlock,
                store: passcodeStore
            ) {
                handlePasscodeUnlockCompletion()
            }
        } else {
            appContent
        }
    }

    private var passcodeUnavailableContent: some View {
        ContentUnavailableView {
            Label(
                Constants.Passcode.unavailableTitle,
                systemImage: Constants.Passcode.unavailableIcon
            )
        } description: {
            Text(Constants.Passcode.unavailableDescription)
        } actions: {
            Button(Constants.retryTitle) {
                passcodeStore.refresh()
            }
        }
    }

    @ViewBuilder
    private var appContent: some View {
        switch bootstrap.state {
        case .idle, .loading:
            ProgressView(Constants.Bootstrap.loadingTitle)
        case .ready(let dependencies):
            FinanceAppMainView(
                financeService: dependencies.financeService,
                accountsStore: dependencies.accountsStore,
                synchronizationStatus: dependencies.synchronizationStatus,
                dataSourceStatus: dependencies.dataSourceStatus,
                networkConnectivity: dependencies.networkConnectivity
            )
        case .failed(let message):
            ContentUnavailableView {
                Label(
                    Constants.Bootstrap.errorTitle,
                    systemImage: Constants.Bootstrap.errorIcon
                )
            } description: {
                Text(message)
            } actions: {
                Button(Constants.retryTitle) {
                    Task {
                        await bootstrap.retry()
                    }
                }
            }
        }
    }

    private var isPrivacyProtectionEnabled: Bool {
        switch scenePhase {
        case .active:
            false
        case .inactive:
            !isBiometricPresentationActive
                && !biometricService.isAuthenticating
        case .background:
            true
        @unknown default:
            true
        }
    }

    // MARK: - Private Methods

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .inactive:
            recordInactivityStartIfNeeded()

        case .background:
            biometricService.cancelAuthentication()
            isBiometricPresentationActive = false
            recordInactivityStartIfNeeded()

        case .active:
            defer { inactiveSince = nil }

            isBiometricPresentationActive = false
            biometricService.refreshAvailability()
            _ = settingsStore.validateBiometricDomainState(
                biometricService.currentDomainState
            )

            guard
                passcodeStore.availability == .configured,
                isAuthenticated,
                let inactiveSince,
                inactiveSince.duration(to: ContinuousClock.now)
                    >= Constants.Passcode.inactivityTimeout
            else {
                return
            }

            isAuthenticated = false

        @unknown default:
            break
        }
    }

    private func recordInactivityStartIfNeeded() {
        guard
            passcodeStore.availability == .configured,
            isAuthenticated,
            inactiveSince == nil
        else {
            return
        }

        inactiveSince = .now
    }

    private func handlePasscodeUnlockCompletion() {
        isAuthenticated = true
    }
}
