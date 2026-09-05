//
//  BiometricSettingsPresentationView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 06.08.2026.
//

import SwiftUI

private enum Constants {
    enum BiometricPanel {
        static let preferredHeightFraction = 0.44
        static let minimumHeight: CGFloat = 365
        static let maximumHeight: CGFloat = 400
    }

    enum PasscodePanel {
        static let preferredHeightFraction = 0.57
        static let minimumHeight: CGFloat = 480
        static let maximumHeight: CGFloat = 510
    }

    static let topPadding: CGFloat = 24
    static let horizontalPadding: CGFloat = 20
    static let contentSpacing: CGFloat = 28
    static let iconContainerSize: CGFloat = 80
    static let iconSize: CGFloat = 42
    static let descriptionHorizontalPadding: CGFloat = 32
    static let controlCornerRadius: CGFloat = 14
    static let controlHorizontalPadding: CGFloat = 16
    static let controlHeight: CGFloat = 64
    static let footnoteSpacing: CGFloat = 4
    static let titleFont = Font.title2.bold()
    static let descriptionFont = Font.body
    static let footnoteFont = Font.caption
    static let iconBackgroundColor = Color.accentColor.opacity(0.1)
    static let controlBackgroundColor = Color(.secondarySystemBackground)
    static var informationText: String {
        AppLocalization.string(
            localized: "Приложение не получает и не хранит ваши биометрические данные."
        )
    }
    static var unavailableMessage: String {
        AppLocalization.string(
            localized: "Биометрическая авторизация сейчас недоступна."
        )
    }
    static var failedMessage: String {
        AppLocalization.string(
            localized: "Не удалось подтвердить личность. Попробуйте ещё раз."
        )
    }
    static var lockedOutMessage: String {
        AppLocalization.string(
            localized: "Биометрия временно заблокирована. Используйте ПИН-код."
        )
    }
    static var alertTitle: String {
        AppLocalization.string(
            localized: "Не удалось изменить настройку"
        )
    }
    static var alertDismissTitle: String { AppLocalization.string(localized: "ОК") }
    static var disableConfirmationTitle: String {
        AppLocalization.string(
            localized: "Отключение биометрии"
        )
    }
}

struct BiometricSettingsPresentationView: View {
    // MARK: - Properties

    @Environment(AppSettingsStore.self) private var settingsStore
    @Environment(BiometricAuthenticationService.self)
    private var biometricService
    @Environment(HapticsService.self) private var hapticsService
    @Environment(PasscodeStore.self) private var passcodeStore

    let type: BiometricType
    let onDismiss: () -> Void

    // MARK: - State

    @State private var errorMessage: String?
    @State private var isConfirmingWithPasscode = false

    // MARK: - View Body

    var body: some View {
        SettingsBottomPanelPresentationView(
            preferredHeightFraction: preferredHeightFraction,
            minimumHeight: minimumHeight,
            maximumHeight: maximumHeight,
            onDismiss: onDismiss
        ) {
            if isConfirmingWithPasscode {
                passcodeConfirmationContent
            } else {
                content
            }
        }
        .alert(
            Constants.alertTitle,
            isPresented: errorIsPresented
        ) {
            Button(Constants.alertDismissTitle, role: .cancel) {}
        } message: {
            Text(errorMessage ?? String())
        }
        .onAppear {
            biometricService.refreshAvailability()
            _ = settingsStore.validateBiometricDomainState(
                biometricService.currentDomainState
            )
        }
        .onDisappear {
            biometricService.cancelAuthentication()
        }
    }

    // MARK: - Private Properties

    private var preferredHeightFraction: CGFloat {
        isConfirmingWithPasscode
            ? Constants.PasscodePanel.preferredHeightFraction
            : Constants.BiometricPanel.preferredHeightFraction
    }

    private var minimumHeight: CGFloat {
        isConfirmingWithPasscode
            ? Constants.PasscodePanel.minimumHeight
            : Constants.BiometricPanel.minimumHeight
    }

    private var maximumHeight: CGFloat {
        isConfirmingWithPasscode
            ? Constants.PasscodePanel.maximumHeight
            : Constants.BiometricPanel.maximumHeight
    }

    private var content: some View {
        VStack(spacing: Constants.contentSpacing) {
            Text(type.title)
                .font(Constants.titleFont)

            Image(systemName: type.iconName)
                .font(.system(size: Constants.iconSize))
                .foregroundStyle(Color.accentColor)
                .frame(
                    width: Constants.iconContainerSize,
                    height: Constants.iconContainerSize
                )
                .background(
                    Constants.iconBackgroundColor,
                    in: Circle()
                )

            Text(type.usageDescription)
                .font(Constants.descriptionFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(
                    .horizontal,
                    Constants.descriptionHorizontalPadding
                )

            VStack(alignment: .leading, spacing: Constants.footnoteSpacing) {
                Toggle(type.title, isOn: biometricToggleBinding)
                    .padding(
                        .horizontal,
                        Constants.controlHorizontalPadding
                    )
                    .frame(height: Constants.controlHeight)
                    .background(
                        Constants.controlBackgroundColor,
                        in: RoundedRectangle(
                            cornerRadius: Constants.controlCornerRadius
                        )
                    )
                    .disabled(biometricService.isAuthenticating)

                Text(Constants.informationText)
                    .font(Constants.footnoteFont)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.top, Constants.topPadding)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var biometricToggleBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.isBiometricUnlockEnabled },
            set: { isEnabled in
                handleBiometricToggle(isEnabled)
            }
        )
    }

    private var passcodeConfirmationContent: some View {
        PasscodeView(
            mode: .verify,
            store: passcodeStore,
            panelTitle: Constants.disableConfirmationTitle
        ) {
            completeBiometricDisabling()
        }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    // MARK: - Private Methods

    private func handleBiometricToggle(_ isEnabled: Bool) {
        Task {
            let result = await biometricService.authenticate()
            handleAuthenticationResult(
                result,
                shouldEnable: isEnabled
            )
        }
    }

    private func handleAuthenticationResult(
        _ result: BiometricAuthenticationResult,
        shouldEnable: Bool
    ) {
        switch result {
        case .success:
            if shouldEnable {
                enableBiometricUnlock()
            } else {
                completeBiometricDisabling()
            }
        case .cancelled:
            break
        case .fallbackRequested:
            if shouldEnable {
                errorMessage = Constants.failedMessage
            } else {
                isConfirmingWithPasscode = true
            }
        case .failed:
            errorMessage = Constants.failedMessage
        case .lockedOut:
            if shouldEnable {
                errorMessage = Constants.lockedOutMessage
            } else {
                isConfirmingWithPasscode = true
            }
        case .unavailable:
            if shouldEnable {
                errorMessage = Constants.unavailableMessage
            } else {
                isConfirmingWithPasscode = true
            }
        }
    }

    private func enableBiometricUnlock() {
        guard let domainState = biometricService.currentDomainState else {
            errorMessage = Constants.unavailableMessage
            return
        }

        settingsStore.enableBiometricUnlock(
            domainState: domainState
        )
        hapticsService.successOccurred()
        onDismiss()
    }

    private func completeBiometricDisabling() {
        settingsStore.disableBiometricUnlock()
        hapticsService.successOccurred()
        onDismiss()
    }
}
