//
//  TransactionsListView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 18.07.2026.
//

import SwiftUI

private enum Constants {
    enum Summary {
        static var incomeTitle: String {
            AppLocalization.string(
                localized: "Доходы, всего"
            )
        }
        static var outcomeTitle: String {
            AppLocalization.string(
                localized: "Расходы, всего"
            )
        }
    }

    enum Sort {
        static var dateTitle: String { AppLocalization.string(localized: "По дате") }
        static var amountTitle: String { AppLocalization.string(localized: "По сумме") }
        static var accessibilityLabel: String {
            AppLocalization.string(
                localized: "Сортировка операций"
            )
        }
        static let icon = "arrow.up.arrow.down"
        static let spacing: CGFloat = 6
        static let horizontalPadding: CGFloat = 12
        static let height: CGFloat = 36
        static let borderOpacity = 0.18
        static let borderWidth: CGFloat = 0.5
        static let font = Font.caption.weight(.medium)
    }

    enum Loading {
        static var title: String {
            AppLocalization.string(
                localized: "Загрузка операций…"
            )
        }
    }

    enum ErrorState {
        static var title: String {
            AppLocalization.string(
                localized: "Не удалось загрузить операции"
            )
        }
        static let icon = "exclamationmark.triangle"
        static var retryTitle: String { AppLocalization.string(localized: "Повторить") }
    }

    enum EmptyState {
        static var title: String { AppLocalization.string(localized: "Операций нет") }
        static let icon = "tray"
        static var description: String {
            AppLocalization.string(
                localized: "За выбранный день операции не найдены"
            )
        }
    }

    enum List {
        nonisolated static let rowHorizontalInset: CGFloat = 16
        nonisolated static let separatorLeading: CGFloat = 64
        static let bottomContentMargin = AddTransactionButtonMetrics.scrollClearance

    }

    enum AddButton {
        static var accessibilityLabel: String {
            AppLocalization.string(
                localized: "Добавить операцию"
            )
        }
        static let trailingPadding = AddTransactionButtonMetrics.trailingPadding
        static let bottomPadding = AddTransactionButtonMetrics.bottomPadding
    }

    static let lastUsedAccountStorageKey =
        "lastUsedTransactionAccountID"
    static let backgroundColor = Color(.systemBackground)
}

struct TransactionsListView: View {
    // MARK: - Properties

    @Environment(AppSettingsStore.self) private var settingsStore
    @Environment(HapticsService.self) private var hapticsService

    private let recoveryGeneration: Int
    private let isActive: Bool
    private let onAnalyticsRequest: () -> Void
    private let onSettingsRequest: () -> Void
    private let onEditorRequest: (TransactionEditorRoute) -> Void

    // MARK: - State

    @State private var viewModel: TransactionsListViewModel
    @AppStorage(Constants.lastUsedAccountStorageKey)
    private var lastUsedAccountID = 0

    // MARK: - Initializers

    init(
        direction: Direction,
        service: any TransactionsScreenServiceProviding,
        accountsStore: AccountsStore,
        recoveryGeneration: Int,
        isActive: Bool,
        onAnalyticsRequest: @escaping () -> Void,
        onSettingsRequest: @escaping () -> Void,
        onEditorRequest:
            @escaping (TransactionEditorRoute) -> Void
    ) {
        self.recoveryGeneration = recoveryGeneration
        self.isActive = isActive
        self.onAnalyticsRequest = onAnalyticsRequest
        self.onSettingsRequest = onSettingsRequest
        self.onEditorRequest = onEditorRequest
        _viewModel = State(
            initialValue: TransactionsListViewModel(
                direction: direction,
                service: service,
                accountsStore: accountsStore
            )
        )
    }
    // MARK: - View Body
    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: .zero) {
            summary
            content
        }
        .overlay(alignment: .bottomTrailing) {
            addTransactionButton
        }
        .adaptiveContentWidth()
        .background(Constants.backgroundColor)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: .zero) {
            FinanceHeaderView {
                DateSelectionButton(selectedDate: $viewModel.selectedDate)
            } analyticsAction: {
                onAnalyticsRequest()
            } settingsAction: {
                onSettingsRequest()
            }
        }
        .task(id: viewModel.selectedDate) {
            await viewModel.loadTransactions()
        }
        .task(id: isActive ? recoveryGeneration : 0) {
            guard isActive, recoveryGeneration > 0 else {
                return
            }
            await viewModel.reloadTransactions()
        }
    }

    // MARK: - Private Properties
    private var addTransactionButton: some View {
        AddTransactionButton(
            accessibilityLabel:
                Constants.AddButton.accessibilityLabel,
            tintColor: settingsStore.tint.color
        ) {
            hapticsService.impactOccurred()
            presentEditor(
                mode: .creation(
                    direction: viewModel.direction,
                    preferredAccountID:
                        lastUsedAccountID > .zero
                        ? lastUsedAccountID
                        : nil
                )
            )
        }
        .padding(.trailing, Constants.AddButton.trailingPadding)
        .padding(.bottom, Constants.AddButton.bottomPadding)
    }

    private var summary: some View {
        TotalSummaryView(
            title: totalTitle,
            amount: viewModel.totalAmount,
            currencyCode: viewModel.currencyCode
        ) {
            sortButton
        }
    }

    private var sortButton: some View {
        Button(action: toggleSortOption) {
            sortButtonLabel
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityLabel(Constants.Sort.accessibilityLabel)
        .accessibilityValue(sortTitle)
    }

    @ViewBuilder
    private var sortButtonLabel: some View {
        if #available(iOS 26.0, *) {
            sortLabel
                .glassEffect(.regular.interactive(), in: Capsule())
        } else {
            sortLabel
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(
                            Color.white.opacity(Constants.Sort.borderOpacity),
                            lineWidth: Constants.Sort.borderWidth
                        )
                }
                .clipShape(Capsule())
        }
    }

    private var sortLabel: some View {
        HStack(spacing: Constants.Sort.spacing) {
            Image(systemName: Constants.Sort.icon)
            Text(sortTitle)
        }
        .font(Constants.Sort.font)
        .foregroundStyle(Color.primary)
        .padding(.horizontal, Constants.Sort.horizontalPadding)
        .frame(height: Constants.Sort.height)
        .contentShape(Capsule())
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView(Constants.Loading.title)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage {
            ContentUnavailableView {
                Label(
                    Constants.ErrorState.title,
                    systemImage: Constants.ErrorState.icon
                )
            } description: {
                Text(errorMessage)
            } actions: {
                Button(Constants.ErrorState.retryTitle) {
                    Task {
                        await viewModel.loadTransactions()
                    }
                }
            }
        } else if viewModel.transactions.isEmpty {
            ContentUnavailableView(
                Constants.EmptyState.title,
                systemImage: Constants.EmptyState.icon,
                description: Text(Constants.EmptyState.description)
            )
        } else {
            transactionsList
        }
    }

    private var transactionsList: some View {
        List(viewModel.sortedTransactions) { transaction in
            Button {
                presentEditor(mode: .editing(transaction))
            } label: {
                TransactionRowView(transaction: transaction)
                    .frame(maxWidth: .infinity)
                    .padding(
                        .horizontal,
                        Constants.List.rowHorizontalInset
                    )
                    .contentShape(.interaction, Rectangle())
            }
            .buttonStyle(.plain)
            .listRowInsets(.init())
            .listRowSeparatorTint(Color(.separator))
            .alignmentGuide(.listRowSeparatorLeading) { _ in
                Constants.List.separatorLeading
            }
            .alignmentGuide(.listRowSeparatorTrailing) { dimensions in
                dimensions.width
                    - Constants.List.rowHorizontalInset
            }
            .accessibilityHint(
                AppLocalization.string(localized: "Открывает изменение операции")
            )
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(
            .bottom,
            Constants.List.bottomContentMargin,
            for: .scrollContent
        )
    }

    private var totalTitle: String {
        switch viewModel.direction {
        case .income:
            Constants.Summary.incomeTitle
        case .outcome:
            Constants.Summary.outcomeTitle
        }
    }

    private var sortTitle: String {
        switch viewModel.sortOption {
        case .date:
            Constants.Sort.dateTitle
        case .amount:
            Constants.Sort.amountTitle
        }
    }

    private func presentEditor(mode: TransactionEditorMode) {
        onEditorRequest(
            TransactionEditorRoute(
                mode: mode,
                onSave: handleSavedTransaction,
                onDelete: viewModel.removeTransaction
            )
        )
    }

    private func toggleSortOption() {
        viewModel.sortOption.toggle()
    }

    private func handleSavedTransaction(
        _ transaction: Transaction
    ) {
        lastUsedAccountID = transaction.account.id
        viewModel.applySavedTransaction(transaction)
    }

}
