//
//  SettingsView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 05.08.2026.
//

import SwiftUI

private enum SettingsRoute: Hashable, Identifiable {
    case theme
    case language
    case passcode(PasscodeSettingsAction)
    case biometrics(BiometricType)

    var id: Self { self }
}

private enum PasscodeSettingsAction: Hashable {
    case setup
    case change
    case reset

    var mode: PasscodeMode {
        switch self {
        case .setup:
            .setup
        case .change:
            .change
        case .reset:
            .verify
        }
    }
}

private enum Constants {
    static var navigationTitle: String {
        AppLocalization.string(
            localized: "Настройки"
        )
    }
    static var appearanceSectionTitle: String {
        AppLocalization.string(
            localized: "Оформление"
        )
    }
    static var themeTitle: String { AppLocalization.string(localized: "Тема") }
    static var languageTitle: String { AppLocalization.string(localized: "Язык") }
    static var tintSectionTitle: String {
        AppLocalization.string(
            localized: "Акцентный цвет"
        )
    }
    static var hapticsToggleTitle: String {
        AppLocalization.string(
            localized: "Вибрация"
        )
    }
    static var securitySectionTitle: String {
        AppLocalization.string(
            localized: "Безопасность"
        )
    }
    static var changePasscodeTitle: String {
        AppLocalization.string(
            localized: "Изменить ПИН-код"
        )
    }
    static var setupPasscodeTitle: String {
        AppLocalization.string(
            localized: "Установить ПИН-код"
        )
    }
    static var resetPasscodeTitle: String {
        AppLocalization.string(
            localized: "Сбросить ПИН-код"
        )
    }
    static var resetPasscodeErrorTitle: String {
        AppLocalization.string(
            localized: "Не удалось сбросить ПИН-код"
        )
    }
    static var dismissErrorTitle: String {
        AppLocalization.string(localized: "ОК")
    }
    static var enabledTitle: String { AppLocalization.string(localized: "Включено") }
    static var disabledTitle: String { AppLocalization.string(localized: "Выключено") }
    static let closeIcon = "xmark"
    static var closeAccessibilityLabel: String {
        AppLocalization.string(
            localized: "Закрыть настройки"
        )
    }
    static let backdropOpacity = 0.5
    static let disclosureIcon = "chevron.right"
    static let disclosureIconFont = Font.footnote.weight(.semibold)
    static let tintSpacing: CGFloat = 12
    static let tintControlSize: CGFloat = 44
    static let tintCircleSize: CGFloat = 32
    static let selectedTintIcon = "checkmark"
    static let selectedTintIconFont = Font.caption.bold()
    static let selectedTintIconColor = Color.white
}

struct SettingsView: View {
    // MARK: - Properties

    @Environment(AppSettingsStore.self) private var settingsStore
    @Environment(HapticsService.self) private var hapticsService
    @Environment(PasscodeStore.self) private var passcodeStore
    @Environment(BiometricAuthenticationService.self)
    private var biometricService

    private let onDismiss: () -> Void

    // MARK: - State

    @State private var presentedRoute: SettingsRoute?
    @State private var resetPasscodeErrorMessage: String?

    // MARK: - Initializers

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    // MARK: - View Body

    var body: some View {
        @Bindable var hapticsService = hapticsService

        List {
            Section(Constants.appearanceSectionTitle) {
                Button {
                    presentedRoute = .theme
                } label: {
                    HStack {
                        Text(Constants.themeTitle)

                        Spacer()

                        Text(settingsStore.theme.title)
                            .foregroundStyle(.secondary)

                        Image(systemName: Constants.disclosureIcon)
                            .font(Constants.disclosureIconFont)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    presentedRoute = .language
                } label: {
                    HStack {
                        Text(Constants.languageTitle)

                        Spacer()

                        Text(settingsStore.language.nativeName)
                            .foregroundStyle(.secondary)

                        Image(systemName: Constants.disclosureIcon)
                            .font(Constants.disclosureIconFont)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Section(Constants.tintSectionTitle) {
                tintPicker
            }

            Section {
                Toggle(
                    Constants.hapticsToggleTitle,
                    isOn: $hapticsService.isEnabled
                )
            }

            Section(Constants.securitySectionTitle) {
                passcodeSettings
            }
        }
        .navigationTitle(Constants.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: onDismiss) {
                    Image(systemName: Constants.closeIcon)
                        .foregroundStyle(Color.primary)
                }
                .accessibilityLabel(
                    Constants.closeAccessibilityLabel
                )
            }
        }
        .overlay {
            if presentedRoute != nil {
                Color.black
                    .opacity(Constants.backdropOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .adaptiveFullScreenCover(item: $presentedRoute) { route in
            presentedView(for: route)
        }
        .alert(
            Constants.resetPasscodeErrorTitle,
            isPresented: resetPasscodeErrorIsPresented
        ) {
            Button(Constants.dismissErrorTitle, role: .cancel) {}
        } message: {
            if let resetPasscodeErrorMessage {
                Text(resetPasscodeErrorMessage)
            }
        }
        .onAppear {
            biometricService.refreshAvailability()
            _ = settingsStore.validateBiometricDomainState(
                biometricService.currentDomainState
            )
        }
        .preferredColorScheme(settingsStore.theme.colorScheme)
        .tint(settingsStore.tint.color)
    }

    @ViewBuilder
    private func presentedView(for route: SettingsRoute) -> some View {
        Group {
            switch route {
            case .theme:
                ThemeSelectionPresentationView(
                    selection: themeSelection,
                    title: Constants.themeTitle,
                    onDismiss: dismissPresentedView
                )

            case .language:
                LanguageSelectionPresentationView(
                    selection: languageSelection,
                    onDismiss: dismissPresentedView
                )

            case .passcode(let action):
                PasscodeChangePresentationView(
                    store: passcodeStore,
                    mode: action.mode,
                    title: passcodeTitle(for: action),
                    onDismiss: dismissPresentedView,
                    onCompletion: {
                        completePasscodeAction(action)
                    }
                )

            case .biometrics(let type):
                BiometricSettingsPresentationView(
                    type: type,
                    onDismiss: dismissPresentedView
                )
            }
        }
        .preferredColorScheme(settingsStore.theme.colorScheme)
        .tint(settingsStore.tint.color)
    }

    private var biometricStateTitle: String {
        settingsStore.isBiometricUnlockEnabled
            ? Constants.enabledTitle
            : Constants.disabledTitle
    }

    @ViewBuilder
    private var passcodeSettings: some View {
        switch passcodeStore.availability {
        case .notConfigured:
            Button(Constants.setupPasscodeTitle) {
                presentedRoute = .passcode(.setup)
            }
            .foregroundStyle(.primary)

        case .configured:
            Button(Constants.changePasscodeTitle) {
                presentedRoute = .passcode(.change)
            }
            .foregroundStyle(.primary)

            Button(
                Constants.resetPasscodeTitle,
                role: .destructive
            ) {
                presentedRoute = .passcode(.reset)
            }

            if let biometricType = biometricService.type {
                Button {
                    presentedRoute = .biometrics(biometricType)
                } label: {
                    HStack {
                        Text(biometricType.title)

                        Spacer()

                        Text(biometricStateTitle)
                            .foregroundStyle(.secondary)

                        Image(systemName: Constants.disclosureIcon)
                            .font(Constants.disclosureIconFont)
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

        case .unavailable:
            EmptyView()
        }
    }

    private var themeSelection: Binding<AppTheme> {
        Binding(
            get: { settingsStore.theme },
            set: { settingsStore.theme = $0 }
        )
    }

    private var languageSelection: Binding<AppLanguage> {
        Binding(
            get: { settingsStore.language },
            set: { settingsStore.language = $0 }
        )
    }

    private func dismissPresentedView() {
        presentedRoute = nil
    }

    private func passcodeTitle(
        for action: PasscodeSettingsAction
    ) -> String {
        switch action {
        case .setup:
            Constants.setupPasscodeTitle
        case .change:
            Constants.changePasscodeTitle
        case .reset:
            Constants.resetPasscodeTitle
        }
    }

    private func completePasscodeAction(
        _ action: PasscodeSettingsAction
    ) {
        guard action == .reset else {
            dismissPresentedView()
            return
        }

        do {
            try passcodeStore.resetPasscode()
            settingsStore.disableBiometricUnlock()
            dismissPresentedView()
        } catch {
            resetPasscodeErrorMessage = error.localizedDescription
        }
    }

    private var resetPasscodeErrorIsPresented: Binding<Bool> {
        Binding(
            get: { resetPasscodeErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    resetPasscodeErrorMessage = nil
                }
            }
        )
    }

    private var tintPicker: some View {
        HStack(spacing: Constants.tintSpacing) {
            ForEach(AppTint.allCases) { tint in
                Button {
                    settingsStore.tint = tint
                } label: {
                    ZStack {
                        Circle()
                            .fill(tint.color)
                            .frame(
                                width: Constants.tintCircleSize,
                                height: Constants.tintCircleSize
                            )

                        if settingsStore.tint == tint {
                            Image(systemName: Constants.selectedTintIcon)
                                .font(Constants.selectedTintIconFont)
                                .foregroundStyle(
                                    Constants.selectedTintIconColor
                                )
                        }
                    }
                    .frame(
                        width: Constants.tintControlSize,
                        height: Constants.tintControlSize
                    )
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tint.accessibilityLabel)
                .accessibilityAddTraits(
                    settingsStore.tint == tint ? .isSelected : []
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
}
