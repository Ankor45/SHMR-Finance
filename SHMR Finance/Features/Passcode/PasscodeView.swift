//
//  PasscodeView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 05.08.2026.
//

import SwiftUI

private enum Constants {
    static var accessibilityFormat: String {
        AppLocalization.string(
            localized: "Введено цифр: %d из %d"
        )
    }
    static var secondsFormat: String { AppLocalization.string(localized: "%d сек.") }
    static let minutesFormat = "%d:%02d"
    static let secondsPerMinute = 60
    static let indicatorSize: CGFloat = 16
    static let indicatorSpacing: CGFloat = 18
    static let contentSpacing: CGFloat = 28
    static let horizontalPadding: CGFloat = 24
    static let maximumContentWidth: CGFloat = 480
    static let panelTitleTopPadding: CGFloat = 16
    static let panelPromptBottomPadding: CGFloat = 28
    static let panelKeypadHeight: CGFloat = 280
    static let panelStatusHeight: CGFloat = 57
    static let statusHeight: CGFloat = 44
    static var lockoutFormat: String {
        AppLocalization.string(
            localized: "Повторите через %@"
        )
    }
    static let titleFont = Font.title2.bold()
    static let panelPromptFont = Font.body
    static let statusFont = Font.callout
    static let errorColor = Color.red
    static let backgroundColor = Color(.systemBackground)
    static let keypadBackgroundColor = Color(.systemGray6)
}

struct PasscodeView: View {
    // MARK: - Properties

    @Environment(HapticsService.self) private var hapticsService
    @Environment(AppSettingsStore.self) private var settingsStore
    @Environment(BiometricAuthenticationService.self)
    private var biometricService

    private let mode: PasscodeMode
    private let store: PasscodeStore
    private let panelTitle: String?
    private let onCompletion: () -> Void

    // MARK: - State

    @State private var viewModel: PasscodeViewModel
    @State private var remainingLockoutSeconds: Int?
    @State private var hasAttemptedAutomaticBiometrics = false

    // MARK: - Initializers

    init(
        mode: PasscodeMode,
        store: PasscodeStore,
        panelTitle: String? = nil,
        onCompletion: @escaping () -> Void
    ) {
        self.mode = mode
        self.store = store
        self.panelTitle = panelTitle
        self.onCompletion = onCompletion
        _viewModel = State(
            initialValue: PasscodeViewModel(
                mode: mode,
                store: store
            )
        )
    }

    // MARK: - View Body

    var body: some View {
        Group {
            if let panelTitle {
                panelContent(title: panelTitle)
            } else {
                fullScreenContent
            }
        }
        .frame(maxWidth: Constants.maximumContentWidth)
        .frame(maxWidth: .infinity)
        .background(Constants.backgroundColor)
        .task(id: store.lockoutDeadline) {
            await updateLockoutCountdown()
        }
        .task {
            await requestAutomaticBiometricAuthentication()
        }
        .onDisappear {
            guard mode == .unlock else {
                return
            }

            biometricService.cancelAuthentication()
        }
    }

    // MARK: - Private Properties

    private var fullScreenContent: some View {
        VStack(spacing: .zero) {
            VStack(spacing: Constants.contentSpacing) {
                Text(viewModel.title)
                    .font(Constants.titleFont)
                    .multilineTextAlignment(.center)

                passcodeIndicators
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                statusText
            }
            .padding(.horizontal, Constants.horizontalPadding)

            NumericKeypadView(
                isInputEnabled: !isLocked,
                accessoryAction: biometricKeypadAction,
                onDigit: handleDigit,
                onDelete: viewModel.deleteLastDigit
            )
        }
    }

    private var passcodeIndicators: some View {
        HStack(spacing: Constants.indicatorSpacing) {
            ForEach(0..<PasscodeStore.passcodeLength, id: \.self) { index in
                Circle()
                    .fill(
                        index < viewModel.enteredPasscode.count
                            ? Color.accentColor
                            : Color.clear
                    )
                    .overlay {
                        Circle()
                            .strokeBorder(Color.secondary)
                    }
                    .frame(
                        width: Constants.indicatorSize,
                        height: Constants.indicatorSize
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            String(
                format: Constants.accessibilityFormat,
                viewModel.enteredPasscode.count,
                PasscodeStore.passcodeLength
            )
        )
    }

    @ViewBuilder
    private var statusText: some View {
        Group {
            if let remainingLockoutSeconds {
                Text(
                    String(
                        format: Constants.lockoutFormat,
                        formattedDuration(remainingLockoutSeconds)
                    )
                )
                .foregroundStyle(Constants.errorColor)
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(Constants.errorColor)
            } else {
                Color.clear
                    .accessibilityHidden(true)
            }
        }
        .font(Constants.statusFont)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, minHeight: Constants.statusHeight)
    }

    private var isLocked: Bool {
        store.remainingLockoutSeconds() != nil
    }

    private var biometricKeypadAction: NumericKeypadAccessoryAction? {
        guard
            mode == .unlock,
            settingsStore.isBiometricUnlockEnabled,
            viewModel.enteredPasscode.isEmpty,
            biometricService.isAvailable,
            let type = biometricService.type
        else {
            return nil
        }

        return NumericKeypadAccessoryAction(
            iconName: type.iconName,
            accessibilityLabel: type.title,
            action: requestBiometricAuthentication
        )
    }

    // MARK: - Private Methods

    private func panelContent(title: String) -> some View {
        VStack(spacing: .zero) {
            VStack(spacing: .zero) {
                Text(title)
                    .font(Constants.titleFont)
                    .multilineTextAlignment(.leading)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(
                        .top,
                        Constants.panelTitleTopPadding
                    )

                Spacer(minLength: .zero)

                Text(viewModel.title)
                    .font(Constants.panelPromptFont)
                    .multilineTextAlignment(.center)
                    .padding(
                        .bottom,
                        Constants.panelPromptBottomPadding
                    )

                passcodeIndicators
                statusText
                    .frame(height: Constants.panelStatusHeight)
            }
            .padding(.horizontal, Constants.horizontalPadding)

            NumericKeypadView(
                isInputEnabled: !isLocked,
                onDigit: handleDigit,
                onDelete: viewModel.deleteLastDigit
            )
            .frame(
                height: Constants.panelKeypadHeight,
                alignment: .top
            )
            .background(
                Constants.keypadBackgroundColor,
                ignoresSafeAreaEdges: .bottom
            )
        }
    }

    private func handleDigit(_ digit: Int) {
        guard case .completed = viewModel.appendDigit(digit) else {
            return
        }

        hapticsService.successOccurred()
        onCompletion()
    }

    private func requestBiometricAuthentication() {
        Task {
            await authenticateWithBiometrics()
        }
    }

    private func requestAutomaticBiometricAuthentication() async {
        guard !hasAttemptedAutomaticBiometrics else {
            return
        }

        hasAttemptedAutomaticBiometrics = true

        guard mode == .unlock else {
            return
        }

        await authenticateWithBiometrics()
    }

    private func authenticateWithBiometrics() async {
        guard
            viewModel.enteredPasscode.isEmpty,
            canUseBiometricUnlock()
        else {
            return
        }

        guard case .success = await biometricService.authenticate() else {
            return
        }

        hapticsService.successOccurred()
        onCompletion()
    }

    private func canUseBiometricUnlock() -> Bool {
        biometricService.refreshAvailability()

        guard biometricService.isAvailable else {
            return false
        }

        return settingsStore.validateBiometricDomainState(
            biometricService.currentDomainState
        )
    }

    private func updateLockoutCountdown() async {
        while let remainingSeconds = store.remainingLockoutSeconds() {
            remainingLockoutSeconds = remainingSeconds

            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return
            }
        }

        remainingLockoutSeconds = nil
    }

    private func formattedDuration(_ seconds: Int) -> String {
        guard seconds >= Constants.secondsPerMinute else {
            return String(
                format: Constants.secondsFormat,
                seconds
            )
        }

        let minutes = seconds / Constants.secondsPerMinute
        let remainingSeconds = seconds % Constants.secondsPerMinute

        return String(
            format: Constants.minutesFormat,
            minutes,
            remainingSeconds
        )
    }
}
