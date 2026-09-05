//
//  TransactionEditorAlertsModifier.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import SwiftUI

private enum Constants {
    static var deletionConfirmationTitle: String {
        AppLocalization.string(
            localized: "Удалить операцию?"
        )
    }
    static var deletionConfirmationMessage: String {
        AppLocalization.string(
            localized: "Это действие нельзя отменить."
        )
    }
    static var cancelTitle: String { AppLocalization.string(localized: "Отмена") }
    static var dismissTitle: String { AppLocalization.string(localized: "ОК") }
}

struct TransactionEditorAlertsModifier: ViewModifier {
    // MARK: - Properties

    @Bindable var viewModel: TransactionEditorViewModel
    @Binding var isDeletionPresented: Bool

    let onDelete: () -> Void

    // MARK: - View Modifier

    func body(content: Content) -> some View {
        content
            .alert(
                Constants.deletionConfirmationTitle,
                isPresented: $isDeletionPresented
            ) {
                Button(
                    TransactionEditorDeleteCopy.title,
                    role: .destructive,
                    action: onDelete
                )
                Button(
                    Constants.cancelTitle,
                    role: .cancel
                ) {}
            } message: {
                Text(Constants.deletionConfirmationMessage)
            }
            .alert(
                viewModel.alert?.title ?? String(),
                isPresented: alertBinding
            ) {
                Button(
                    Constants.dismissTitle,
                    role: .cancel
                ) {}
            } message: {
                Text(viewModel.alert?.message ?? String())
            }
    }

    // MARK: - Private Properties

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.alert != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissAlert()
                }
            }
        )
    }
}
