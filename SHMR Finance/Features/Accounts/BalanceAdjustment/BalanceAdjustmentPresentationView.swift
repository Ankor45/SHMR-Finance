//
//  BalanceAdjustmentPresentationView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import SwiftUI
import UIKit

private enum Constants {
    static let heightFraction = 0.71
    static let minimumHeight: CGFloat = 500
    static let maximumHeight: CGFloat = 680
}

struct BalanceAdjustmentPresentationView: View {
    // MARK: - Properties

    private let currencyCode: String
    private let adjustmentDate: Date
    private let onDismiss: () -> Void
    private let onConfirm: (Decimal) async throws -> Void

    // MARK: - State

    @State private var viewModel: BalanceAdjustmentViewModel

    // MARK: - Initializers

    init(
        account: BankAccount,
        adjustmentDate: Date = .now,
        onDismiss: @escaping () -> Void,
        onConfirm: @escaping (Decimal) async throws -> Void
    ) {
        currencyCode = account.currency
        self.adjustmentDate = adjustmentDate
        self.onDismiss = onDismiss
        self.onConfirm = onConfirm
        _viewModel = State(
            initialValue: BalanceAdjustmentViewModel(
                initialBalance: account.balance
            )
        )
    }

    // MARK: - View Body

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .overlay(alignment: .bottom) {
                    panel(height: proxy.size.height)
                }
        }
        .ignoresSafeArea()
        .presentationBackground(.clear)
    }

    // MARK: - Private Methods

    private func panel(height: CGFloat) -> some View {
        BottomPanelView(
            height: panelHeight(for: height),
            isDismissEnabled: !viewModel.isSaving,
            onDismiss: onDismiss
        ) {
            BalanceAdjustmentView(
                viewModel: viewModel,
                currencyCode: currencyCode,
                adjustmentDate: adjustmentDate,
                onDismiss: onDismiss,
                onConfirm: onConfirm
            )
        }
    }

    private func panelHeight(for availableHeight: CGFloat) -> CGFloat {
        guard UIDevice.current.userInterfaceIdiom != .pad else {
            return availableHeight
        }

        let preferredHeight =
            availableHeight * Constants.heightFraction
        let minimumHeight = min(
            Constants.minimumHeight,
            availableHeight
        )
        let maximumHeight = min(
            Constants.maximumHeight,
            availableHeight
        )

        return min(
            max(preferredHeight, minimumHeight),
            maximumHeight
        )
    }
}
