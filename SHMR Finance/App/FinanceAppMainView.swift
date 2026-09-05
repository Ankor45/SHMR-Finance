//
//  FinanceAppMainView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 11.07.2026.
//

import SwiftUI

private enum Constants {
    enum TabBar {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding = AppTabBarMetrics.verticalPadding
    }

    enum ModalBackdrop {
        static let opacity = 0.35
        static let color = Color.black
    }

    enum Synchronization {
        static var title: String {
            AppLocalization.string(
                localized: "Обновление данных…"
            )
        }
        static let spacing: CGFloat = 8
        static let horizontalPadding: CGFloat = 14
        static let verticalPadding: CGFloat = 10
        static let topPadding: CGFloat = 8
        static var issueTitle: String {
            AppLocalization.string(
                localized: "Есть несинхронизированные изменения"
            )
        }
        static var dismissTitle: String { AppLocalization.string(localized: "Скрыть") }
    }

    enum OfflineMode {
        static var title: String { AppLocalization.string(localized: "Офлайн-режим") }
        static let iconName = "wifi.slash"
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 8
    }

    enum AccountsError {
        static var loadingTitle: String {
            AppLocalization.string(
                localized: "Не удалось загрузить счета"
            )
        }
        static var refreshingTitle: String {
            AppLocalization.string(
                localized: "Не удалось обновить счета"
            )
        }
        static var dismissTitle: String { AppLocalization.string(localized: "ОК") }
    }

}

struct FinanceAppMainView: View {
    // MARK: - Properties
    @Environment(\.locale) private var locale

    private let financeService: any FinanceServiceProviding
    private let accountsStore: AccountsStore
    private let synchronizationStatus: SynchronizationStatusStore
    private let dataSourceStatus: DataSourceStatusStore
    private let networkConnectivity: NetworkConnectivityStore

    // MARK: - State
    @State private var selectedTab: AppTab = .expenses
    @State private var analyticsDirection: Direction = .outcome
    @State private var isAnalyticsPresented = false
    @State private var isSettingsPresented = false
    @State private var balanceAdjustmentRoute: BalanceAdjustmentRoute?
    @State private var transactionEditorRoute: TransactionEditorRoute?

    // MARK: - Initializers
    init(
        financeService: any FinanceServiceProviding,
        accountsStore: AccountsStore,
        synchronizationStatus: SynchronizationStatusStore,
        dataSourceStatus: DataSourceStatusStore,
        networkConnectivity: NetworkConnectivityStore
    ) {
        self.financeService = financeService
        self.accountsStore = accountsStore
        self.synchronizationStatus = synchronizationStatus
        self.dataSourceStatus = dataSourceStatus
        self.networkConnectivity = networkConnectivity
    }

    // MARK: - View Body
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(
                AppTab.expenses.title,
                systemImage: AppTab.expenses.iconName,
                value: AppTab.expenses
            ) {
                NavigationStack {
                    TransactionsListView(
                        direction: .outcome,
                        service: financeService,
                        accountsStore: accountsStore,
                        recoveryGeneration:
                            networkConnectivity.recoveryGeneration,
                        isActive: selectedTab == .expenses,
                        onAnalyticsRequest: {
                            presentAnalytics(direction: .outcome)
                        },
                        onSettingsRequest: presentSettings
                    ) { route in
                        transactionEditorRoute = route
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }

            Tab(
                AppTab.income.title,
                systemImage: AppTab.income.iconName,
                value: AppTab.income
            ) {
                NavigationStack {
                    TransactionsListView(
                        direction: .income,
                        service: financeService,
                        accountsStore: accountsStore,
                        recoveryGeneration:
                            networkConnectivity.recoveryGeneration,
                        isActive: selectedTab == .income,
                        onAnalyticsRequest: {
                            presentAnalytics(direction: .income)
                        },
                        onSettingsRequest: presentSettings
                    ) { route in
                        transactionEditorRoute = route
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }

            Tab(
                AppTab.accounts.title,
                systemImage: AppTab.accounts.iconName,
                value: AppTab.accounts
            ) {
                NavigationStack {
                    AccountsListView(
                        store: accountsStore,
                        onAnalyticsRequest: {
                            presentAnalytics(direction: .outcome)
                        },
                        onSettingsRequest: presentSettings
                    ) { route in
                        balanceAdjustmentRoute = route
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }
        }
        .id(locale.identifier)
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            VStack(spacing: .zero) {
                if networkConnectivity.isDisconnected
                    || dataSourceStatus.isUsingLocalData {
                    offlineModeBanner
                }

                LiquidGlassTabBar(selection: $selectedTab)
                    .padding(
                        .horizontal,
                        Constants.TabBar.horizontalPadding
                    )
                    .padding(
                        .vertical,
                        Constants.TabBar.verticalPadding
                    )
            }
        }
        .overlay {
            if balanceAdjustmentRoute != nil
                || transactionEditorRoute != nil {
                Constants.ModalBackdrop.color
                    .opacity(Constants.ModalBackdrop.opacity)
                    .ignoresSafeArea()
            }
        }
        .overlay(alignment: .top) {
            synchronizationStatusOverlay
        }
        .adaptiveFullScreenCover(
            item: $balanceAdjustmentRoute
        ) { route in
            BalanceAdjustmentPresentationView(
                account: route.account,
                onDismiss: {
                    balanceAdjustmentRoute = nil
                },
                onConfirm: route.onConfirm
            )
        }
        .adaptiveFullScreenCover(
            item: $transactionEditorRoute
        ) { route in
            TransactionEditorPresentationView(
                mode: route.mode,
                service: financeService,
                accountsStore: accountsStore,
                onSave: route.onSave,
                onDelete: route.onDelete
            )
        }
        .adaptiveFullScreenCover(
            isPresented: $isSettingsPresented
        ) {
            NavigationStack {
                SettingsView(onDismiss: dismissSettings)
            }
        }
        .adaptiveFullScreenCover(
            isPresented: $isAnalyticsPresented
        ) {
            AnalyticsPresentationView(
                initialDirection: analyticsDirection,
                service: financeService,
                accountsStore: accountsStore
            )
        }
        .alert(
            accountsErrorTitle,
            isPresented: accountsErrorIsPresented
        ) {
            Button(
                Constants.AccountsError.dismissTitle,
                role: .cancel
            ) {}
        } message: {
            Text(accountsStore.errorMessage ?? String())
        }
        .task(id: networkConnectivity.recoveryGeneration) {
            guard networkConnectivity.recoveryGeneration > 0 else {
                return
            }
            await recoverRemoteMetadata()
        }
    }

    // MARK: - Private Properties

    private var offlineModeBanner: some View {
        Label(
            Constants.OfflineMode.title,
            systemImage: Constants.OfflineMode.iconName
        )
        .font(.callout.weight(.medium))
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Constants.OfflineMode.horizontalPadding)
        .padding(.vertical, Constants.OfflineMode.verticalPadding)
        .foregroundStyle(.primary)
        .background(.gray.opacity(0.2))
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var synchronizationStatusOverlay: some View {
        if accountsStore.isRefreshing {
            HStack(spacing: Constants.Synchronization.spacing) {
                ProgressView()
                Text(Constants.Synchronization.title)
            }
            .font(.callout)
            .padding(
                .horizontal,
                Constants.Synchronization.horizontalPadding
            )
            .padding(
                .vertical,
                Constants.Synchronization.verticalPadding
            )
            .background(.regularMaterial, in: Capsule())
            .padding(.top, Constants.Synchronization.topPadding)
            .allowsHitTesting(false)
            .accessibilityElement(children: .combine)
        } else if !synchronizationStatus.issues.isEmpty,
                  !synchronizationStatus.isDismissed {
            HStack(spacing: Constants.Synchronization.spacing) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(Constants.Synchronization.issueTitle)
                    .lineLimit(2)
                Button(Constants.Synchronization.dismissTitle) {
                    synchronizationStatus.dismiss()
                }
                .buttonStyle(.borderless)
                .frame(minWidth: 44, minHeight: 44)
            }
            .font(.callout)
            .padding(.horizontal, Constants.Synchronization.horizontalPadding)
            .background(.regularMaterial, in: Capsule())
            .padding(.horizontal, Constants.Synchronization.horizontalPadding)
            .padding(.top, Constants.Synchronization.topPadding)
        }
    }

    private var accountsErrorIsPresented: Binding<Bool> {
        Binding(
            get: {
                guard
                    transactionEditorRoute == nil,
                    balanceAdjustmentRoute == nil,
                    !isSettingsPresented,
                    !isAnalyticsPresented
                else {
                    return false
                }

                return accountsStore.errorMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    accountsStore.dismissError()
                }
            }
        )
    }

    private var accountsErrorTitle: String {
        accountsStore.accounts.isEmpty
            ? Constants.AccountsError.loadingTitle
            : Constants.AccountsError.refreshingTitle
    }

    // MARK: - Private Methods

    private func presentSettings() {
        isSettingsPresented = true
    }

    private func presentAnalytics(direction: Direction) {
        analyticsDirection = direction
        isAnalyticsPresented = true
    }

    private func dismissSettings() {
        isSettingsPresented = false
    }

    private func recoverRemoteMetadata() async {
        async let accounts: Void = accountsStore.refresh()
        async let categories: Void = refreshCategories()

        _ = await (accounts, categories)
    }

    private func refreshCategories() async {
        _ = try? await financeService.getCategories()
    }
}
