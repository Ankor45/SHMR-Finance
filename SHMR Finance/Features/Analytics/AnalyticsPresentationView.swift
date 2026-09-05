//
//  AnalyticsPresentationView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 29.07.2026.
//

import SwiftUI

struct AnalyticsPresentationView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss

    let initialDirection: Direction
    let service: any TransactionsScreenServiceProviding
    let accountsStore: AccountsStore

    // MARK: - View Body

    var body: some View {
        AnalyticsViewControllerRepresentable(
            initialDirection: initialDirection,
            service: service,
            accountsStore: accountsStore,
            onBack: { dismiss() }
        )
    }
}

private struct AnalyticsViewControllerRepresentable:
    UIViewControllerRepresentable {
    let initialDirection: Direction
    let service: any TransactionsScreenServiceProviding
    let accountsStore: AccountsStore
    let onBack: () -> Void

    func makeUIViewController(
        context: Context
    ) -> AnalyticsViewController {
        AnalyticsViewController(
            initialDirection: initialDirection,
            service: service,
            accountsStore: accountsStore,
            onBack: onBack
        )
    }

    func updateUIViewController(
        _ viewController: AnalyticsViewController,
        context: Context
    ) {
        viewController.onBack = onBack
    }

    static func dismantleUIViewController(
        _ viewController: AnalyticsViewController,
        coordinator: Void
    ) {
        viewController.stopLoading()
    }
}
