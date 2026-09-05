//
//  AccountsListView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import SwiftUI

private enum Constants {
    enum Summary {
        static var title: String { AppLocalization.string(localized: "Баланс, всего") }
    }

    enum Header {
        static var dateAccessibilityLabel: String {
            AppLocalization.string(
                localized: "Текущая дата"
            )
        }
    }

    enum Loading {
        static var title: String {
            AppLocalization.string(
                localized: "Загрузка счетов…"
            )
        }
    }

    enum ErrorState {
        static var title: String {
            AppLocalization.string(
                localized: "Не удалось загрузить счета"
            )
        }
        static let icon = "exclamationmark.triangle"
        static var retryTitle: String { AppLocalization.string(localized: "Повторить") }
    }

    enum EmptyState {
        static var title: String { AppLocalization.string(localized: "Счетов нет") }
        static let icon = "wallet.bifold"
        static var description: String {
            AppLocalization.string(
                localized: "Добавленные счета появятся здесь"
            )
        }
    }

    enum List {
        static let rowHorizontalInset: CGFloat = 16
        nonisolated static let separatorLeading: CGFloat = 64
        static let bottomContentMargin =
            AppTabBarMetrics.scrollClearance

        static let rowInsets = EdgeInsets(
            top: .zero,
            leading: rowHorizontalInset,
            bottom: .zero,
            trailing: rowHorizontalInset
        )
    }

    enum BalancePrivacy {
        static let storageKey = "isAccountBalanceHidden"
        static let animation = Animation.easeInOut(duration: 0.2)
        static var hideAccessibilityAction: String {
            AppLocalization.string(
                localized: "Скрыть баланс"
            )
        }
        static var showAccessibilityAction: String {
            AppLocalization.string(
                localized: "Показать баланс"
            )
        }
    }

    static let backgroundColor = Color(.systemBackground)
}

struct AccountsListView: View {
    // MARK: - Properties

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion

    @Bindable private var store: AccountsStore
    private let onAnalyticsRequest: () -> Void
    private let onSettingsRequest: () -> Void
    private let onBalanceAdjustmentRequest:
        (BalanceAdjustmentRoute) -> Void
    // MARK: - State

    @State private var currentDate: Date
    @AppStorage(Constants.BalancePrivacy.storageKey)
    private var isBalanceHidden = false
    // MARK: - Initializers

    init(
        store: AccountsStore,
        currentDate: Date = .now,
        onAnalyticsRequest: @escaping () -> Void,
        onSettingsRequest: @escaping () -> Void,
        onBalanceAdjustmentRequest:
            @escaping (BalanceAdjustmentRoute) -> Void
    ) {
        self.store = store
        self.onAnalyticsRequest = onAnalyticsRequest
        self.onSettingsRequest = onSettingsRequest
        self.onBalanceAdjustmentRequest = onBalanceAdjustmentRequest
        _currentDate = State(initialValue: currentDate)
    }
    // MARK: - View Body

    var body: some View {
        VStack(spacing: .zero) {
            TotalSummaryView(
                title: Constants.Summary.title,
                amount: totalBalance,
                currencyCode: currencyCode,
                isAmountHidden: isBalanceHidden
            )
            .accessibilityAction(
                named: balanceVisibilityAccessibilityAction
            ) {
                toggleBalanceVisibility()
            }

            content
        }
        .background {
            ShakeDetectorView(onShake: toggleBalanceVisibility)
                .frame(width: .zero, height: .zero)
                .accessibilityHidden(true)
        }
        .adaptiveContentWidth()
        .background(Constants.backgroundColor)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: .zero) {
            FinanceHeaderView {
                DateBadgeView(
                    date: currentDate,
                    isInteractive: false
                )
                .accessibilityLabel(
                    Constants.Header.dateAccessibilityLabel
                )
                .accessibilityValue(formattedCurrentDate)
            } analyticsAction: {
                onAnalyticsRequest()
            } settingsAction: {
                onSettingsRequest()
            }
        }
        .task {
            await store.ensureFresh()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: .NSCalendarDayChanged
            )
        ) { _ in
            updateCurrentDate()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else {
                return
            }

            updateCurrentDate()

            Task {
                await store.refresh()
            }
        }
    }
    // MARK: - Private Properties

    @ViewBuilder
    private var content: some View {
        if store.isLoading {
            ProgressView(Constants.Loading.title)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if store.accounts.isEmpty {
            refreshableListState
        } else {
            accountsList
        }
    }

    private var accountsList: some View {
        List(store.accounts) { account in
            AccountRowView(
                account: account,
                isBalanceHidden: isBalanceHidden
            ) {
                openBalanceAdjustment(for: account)
            }
            .listRowInsets(Constants.List.rowInsets)
            .listRowSeparatorTint(Color(.separator))
            .alignmentGuide(.listRowSeparatorLeading) { _ in
                Constants.List.separatorLeading
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(
            .bottom,
            Constants.List.bottomContentMargin,
            for: .scrollContent
        )
        .refreshable {
            await store.refresh()
        }
    }

    private var refreshableListState: some View {
        ScrollView {
            listState
                .containerRelativeFrame(.vertical)
        }
        .scrollBounceBehavior(.always)
        .refreshable {
            await store.refresh()
        }
    }

    @ViewBuilder
    private var listState: some View {
        if let errorMessage = store.loadErrorMessage {
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
                        await store.retry()
                    }
                }
            }
        } else if store.accounts.isEmpty {
            ContentUnavailableView(
                Constants.EmptyState.title,
                systemImage: Constants.EmptyState.icon,
                description: Text(Constants.EmptyState.description)
            )
        }
    }

    private var totalBalance: Decimal {
        store.accounts.reduce(.zero) {
            $0 + $1.balance
        }
    }

    private var currencyCode: String {
        store.accounts.first?.currency
            ?? CurrencyPresentation.defaultCode
    }

    private var formattedCurrentDate: String {
        currentDate.formatted(
            .dateTime
                .day()
                .month(.wide)
                .year()
                .locale(locale)
        )
    }

    private var balanceVisibilityAccessibilityAction: Text {
        Text(
            isBalanceHidden
                ? Constants.BalancePrivacy.showAccessibilityAction
                : Constants.BalancePrivacy.hideAccessibilityAction
        )
    }

    // MARK: - Private Methods

    private func toggleBalanceVisibility() {
        withAnimation(
            accessibilityReduceMotion
                ? nil
                : Constants.BalancePrivacy.animation
        ) {
            isBalanceHidden.toggle()
        }
    }

    private func updateCurrentDate() {
        currentDate = .now
    }

    private func openBalanceAdjustment(for account: BankAccount) {
        let route = BalanceAdjustmentRoute(
            account: account
        ) { newBalance in
            try await store.updateBalance(
                for: account,
                to: newBalance
            )
        }

        onBalanceAdjustmentRequest(route)
    }
}
