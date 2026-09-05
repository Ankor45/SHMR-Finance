//
//  BalanceAdjustmentView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import SwiftUI

private enum Constants {
    enum Navigation {
        static var title: String {
            AppLocalization.string(
                localized: "Корректировка баланса"
            )
        }
        static let closeIcon = "xmark"
        static let confirmIcon = "checkmark"
        static var closeAccessibilityLabel: String {
            AppLocalization.string(
                localized: "Закрыть"
            )
        }
        static var confirmAccessibilityLabel: String {
            AppLocalization.string(
                localized: "Подтвердить"
            )
        }
    }

    enum Information {
        static var dateTitle: String {
            AppLocalization.string(
                localized: "Дата и время"
            )
        }
        static var currencyTitle: String { AppLocalization.string(localized: "Валюта") }
        static let rowHeight: CGFloat = 60
        static let horizontalPadding: CGFloat = 16
        static let titleFont = Font.body
        static let valueFont = Font.body
    }

    enum Amount {
        static let dividerSpacing: CGFloat = 16
    }

    enum ErrorAlert {
        static var title: String {
            AppLocalization.string(
                localized: "Не удалось изменить баланс"
            )
        }
        static var dismissTitle: String { AppLocalization.string(localized: "ОК") }
    }

    static let animation = Animation.easeInOut(duration: 0.2)
}

struct BalanceAdjustmentView: View {
    // MARK: - Properties

    @Environment(HapticsService.self) private var hapticsService
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion

    @Bindable private var viewModel: BalanceAdjustmentViewModel
    private let currencyCode: String
    private let adjustmentDate: Date
    private let onDismiss: () -> Void
    private let onConfirm: (Decimal) async throws -> Void

    // MARK: - Initializers

    init(
        viewModel: BalanceAdjustmentViewModel,
        currencyCode: String,
        adjustmentDate: Date,
        onDismiss: @escaping () -> Void,
        onConfirm: @escaping (Decimal) async throws -> Void
    ) {
        self.viewModel = viewModel
        self.currencyCode = currencyCode
        self.adjustmentDate = adjustmentDate
        self.onDismiss = onDismiss
        self.onConfirm = onConfirm
    }

    // MARK: - View Body

    var body: some View {
        NavigationStack {
            VStack(spacing: .zero) {
                ScrollView {
                    VStack(spacing: .zero) {
                        amountInput
                        information
                    }
                }
                .scrollBounceBehavior(.basedOnSize)

                if viewModel.isKeypadPresented {
                    NumericKeypadView(
                        onDigit: viewModel.appendDigit,
                        onDecimalSeparator:
                            viewModel.appendDecimalSeparator,
                        onDelete: viewModel.deleteLastCharacter
                    )
                    .transition(
                        .move(edge: .bottom)
                            .combined(with: .opacity)
                    )
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle(Constants.Navigation.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    closeButton
                }

                ToolbarItem(placement: .confirmationAction) {
                    confirmButton
                }
            }
        }
        .alert(
            Constants.ErrorAlert.title,
            isPresented: isErrorPresented
        ) {
            Button(Constants.ErrorAlert.dismissTitle, role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? String())
        }
        .animation(
            accessibilityReduceMotion
                ? nil
                : Constants.animation,
            value: viewModel.isKeypadPresented
        )
    }

    // MARK: - Private Properties

    private var amountInput: some View {
        BalanceAmountInputView(
            amountText: viewModel.amountText,
            currencySymbol: displayedCurrency,
            isCurrencyVisible: !viewModel.hasStartedEditing,
            isActive: viewModel.isKeypadPresented,
            isDisabled: viewModel.isSaving,
            onTap: viewModel.presentKeypad,
            onPaste: viewModel.pasteAmount
        )
        .padding(.bottom, Constants.Amount.dividerSpacing)
    }

    private var information: some View {
        VStack(spacing: .zero) {
            Divider()

            informationRow(
                title: Constants.Information.dateTitle,
                value: formattedAdjustmentDate
            )

            Divider()

            informationRow(
                title: Constants.Information.currencyTitle,
                value: displayedCurrency
            )

            Divider()
        }
        .padding(.horizontal, Constants.Information.horizontalPadding)
    }

    private var closeButton: some View {
        Button(role: .cancel, action: onDismiss) {
            Image(systemName: Constants.Navigation.closeIcon)
                .foregroundStyle(.primary)
        }
        .accessibilityLabel(
            Constants.Navigation.closeAccessibilityLabel
        )
        .disabled(viewModel.isSaving)
    }

    private var confirmButton: some View {
        Button(action: handleConfirm) {
            Group {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Image(systemName: Constants.Navigation.confirmIcon)
                        .foregroundStyle(.white)
                }
            }
        }
        .accessibilityLabel(
            Constants.Navigation.confirmAccessibilityLabel
        )
        .buttonStyle(.borderedProminent)
        .clipShape(Circle())
        .disabled(viewModel.isSaving)
    }

    private var displayedCurrency: String {
        CurrencyPresentation.symbol(for: currencyCode)
    }

    private var formattedAdjustmentDate: String {
        adjustmentDate.formatted(
            .dateTime
                .day()
                .month(.wide)
                .hour()
                .minute()
                .locale(locale)
        )
    }

    private var isErrorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissError()
                }
            }
        )
    }

    // MARK: - Private Methods

    private func informationRow(
        title: String,
        value: String
    ) -> some View {
        HStack {
            Text(title)
                .font(Constants.Information.titleFont)

            Spacer()

            Text(value)
                .font(Constants.Information.valueFont)
                .foregroundStyle(.secondary)
        }
        .frame(minHeight: Constants.Information.rowHeight)
    }

    private func handleConfirm() {
        Task {
            let didSave = await viewModel.save(using: onConfirm)

            if didSave {
                hapticsService.successOccurred()
                onDismiss()
            }
        }
    }
}
