//
//  TransactionAccountSelectionView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import SwiftUI

private enum Constants {
    static var navigationTitle: String { AppLocalization.string(localized: "Счёт") }
    static let closeIcon = "xmark"
    static var closeAccessibilityLabel: String {
        AppLocalization.string(
            localized: "Закрыть"
        )
    }
    static let selectedIcon = "checkmark"
    static var emptyTitle: String { AppLocalization.string(localized: "Счетов нет") }
    static let emptyIcon = "wallet.bifold"
    static var emptyDescription: String {
        AppLocalization.string(
            localized: "Для создания операции сначала добавьте счёт"
        )
    }
    static var loadingTitle: String {
        AppLocalization.string(
            localized: "Загрузка счетов…"
        )
    }
    static var errorTitle: String {
        AppLocalization.string(
            localized: "Не удалось загрузить счета"
        )
    }
    static let errorIcon = "exclamationmark.triangle"
    static var retryTitle: String { AppLocalization.string(localized: "Повторить") }
    static var dismissErrorTitle: String { AppLocalization.string(localized: "ОК") }
    static let rowHeight: CGFloat = 50
    static let rowHorizontalPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 28
}

struct TransactionAccountSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    let accounts: [BankAccount]
    let selectedAccountID: Int?
    let isLoading: Bool
    let loadErrorMessage: String?
    let errorMessage: String?
    let onSelect: (BankAccount) -> Void
    let onRetry: () async -> Void
    let onDismissError: () -> Void

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(Constants.navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel) {
                            dismiss()
                        } label: {
                            Image(systemName: Constants.closeIcon)
                                .foregroundStyle(.primary)
                        }
                        .accessibilityLabel(
                            Constants.closeAccessibilityLabel
                        )
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Constants.cornerRadius)
        .alert(
            Constants.errorTitle,
            isPresented: errorIsPresented
        ) {
            Button(
                Constants.dismissErrorTitle,
                role: .cancel
            ) {}
        } message: {
            Text(errorMessage ?? String())
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView(Constants.loadingTitle)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let loadErrorMessage {
            ContentUnavailableView {
                Label(
                    Constants.errorTitle,
                    systemImage: Constants.errorIcon
                )
            } description: {
                Text(loadErrorMessage)
            } actions: {
                Button(Constants.retryTitle) {
                    Task {
                        await onRetry()
                    }
                }
            }
        } else if accounts.isEmpty {
            ContentUnavailableView(
                Constants.emptyTitle,
                systemImage: Constants.emptyIcon,
                description: Text(Constants.emptyDescription)
            )
        } else {
            List(accounts) { account in
                Button {
                    onSelect(account)
                    dismiss()
                } label: {
                    HStack {
                        Text(account.name)
                            .foregroundStyle(.primary)

                        Spacer()

                        if account.id == selectedAccountID {
                            Image(systemName: Constants.selectedIcon)
                                .foregroundStyle(.tint)
                        }
                    }
                    .frame(minHeight: Constants.rowHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowInsets(
                    EdgeInsets(
                        top: .zero,
                        leading: Constants.rowHorizontalPadding,
                        bottom: .zero,
                        trailing: Constants.rowHorizontalPadding
                    )
                )
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    onDismissError()
                }
            }
        )
    }
}
