//
//  TransactionEditorPresentationView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 24.07.2026.
//

import Combine
import SwiftUI
import UIKit

private enum Constants {
    static let defaultHeightFraction = 0.72
    static let minimumHeight: CGFloat = 500
    static let maximumHeight: CGFloat = 680
    static let defaultKeyboardAnimationDuration = 0.25
}

struct TransactionEditorPresentationView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss

    private let categoriesService: any CategoryServiceProviding
    private let onSave: (Transaction) -> Void
    private let onDelete: (Int) -> Void

    // MARK: - State

    @State private var viewModel: TransactionEditorViewModel
    @State private var panelSourceFrame: CGRect?
    @State private var isCommentEditing = false
    @State private var commentBottom: CGFloat = .zero
    @State private var keyboardTop: CGFloat?

    // MARK: - Initializers

    init(
        mode: TransactionEditorMode,
        service: any TransactionsScreenServiceProviding,
        accountsStore: AccountsStore,
        onSave: @escaping (Transaction) -> Void,
        onDelete: @escaping (Int) -> Void
    ) {
        categoriesService = service
        self.onSave = onSave
        self.onDelete = onDelete
        _viewModel = State(
            initialValue: TransactionEditorViewModel(
                mode: mode,
                service: service,
                accountsStore: accountsStore
            )
        )
    }

    // MARK: - View Body

    var body: some View {
        GeometryReader { proxy in
            let availableFrame = proxy.frame(in: .global)

            ZStack(alignment: .bottom) {
                backdrop

                panel(
                    height:
                        panelSourceFrame?.height
                        ?? proxy.size.height
                )
            }
            .onAppear {
                updatePanelSourceFrame(with: availableFrame)
            }
            .onChange(of: availableFrame) {
                _,
                newFrame in
                updatePanelSourceFrame(with: newFrame)
            }
        }
        .ignoresSafeArea(.container)
        .ignoresSafeArea(.keyboard)
        .presentationBackground(.clear)
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIResponder.keyboardWillChangeFrameNotification
            )
        ) { notification in
            updateKeyboard(with: notification)
        }
    }

    // MARK: - Private Methods

    private var backdrop: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(perform: handleBackdropTap)
    }

    private func panel(height: CGFloat) -> some View {
        BottomPanelView(
            height: panelHeight(for: height),
            verticalOffset: panelOffset,
            isDismissEnabled: !viewModel.isProcessing,
            onDismiss: dismissIfPossible
        ) {
            TransactionEditorView(
                viewModel: viewModel,
                categoriesService: categoriesService,
                onDismiss: dismissIfPossible,
                onSave: onSave,
                onDelete: onDelete,
                isCommentEditing: $isCommentEditing,
                onCommentBottomChanged: {
                    guard !isCommentEditing else {
                        return
                    }

                    commentBottom = $0
                }
            )
        }
    }

    private func panelHeight(for availableHeight: CGFloat) -> CGFloat {
        guard UIDevice.current.userInterfaceIdiom != .pad else {
            return availableHeight
        }

        let preferredHeight =
            availableHeight * Constants.defaultHeightFraction
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

    private func handleBackdropTap() {
        isCommentEditing = false
        dismissIfPossible()
    }

    private func dismissIfPossible() {
        guard !viewModel.isProcessing else {
            return
        }

        dismiss()
    }

    private var panelOffset: CGFloat {
        guard
            let panelSourceFrame,
            isCommentEditing,
            let resolvedKeyboardTop = keyboardTop,
            commentBottom > .zero
        else {
            return .zero
        }

        guard resolvedKeyboardTop < panelSourceFrame.maxY else {
            return .zero
        }

        let requiredShift = max(
            .zero,
            commentBottom - resolvedKeyboardTop
        )

        return -requiredShift
    }

    private func updatePanelSourceFrame(
        with availableFrame: CGRect
    ) {
        guard let panelSourceFrame else {
            self.panelSourceFrame = availableFrame
            return
        }

        let didWidthChange =
            abs(panelSourceFrame.width - availableFrame.width) > 1
        let didOriginChange =
            abs(panelSourceFrame.minX - availableFrame.minX) > 1
            || abs(panelSourceFrame.minY - availableFrame.minY) > 1

        if didWidthChange || didOriginChange {
            self.panelSourceFrame = availableFrame
        } else if availableFrame.height > panelSourceFrame.height {
            self.panelSourceFrame = CGRect(
                origin: panelSourceFrame.origin,
                size: CGSize(
                    width: panelSourceFrame.width,
                    height: availableFrame.height
                )
            )
        }
    }

    private func updateKeyboard(
        with notification: Notification
    ) {
        guard
            let panelSourceFrame,
            let keyboardFrame = (
                notification.userInfo?[
                    UIResponder.keyboardFrameEndUserInfoKey
                ] as? NSValue
            )?.cgRectValue
        else {
            return
        }

        let duration =
            notification.userInfo?[
                UIResponder.keyboardAnimationDurationUserInfoKey
            ] as? Double
            ?? Constants.defaultKeyboardAnimationDuration
        let overlapsPanel =
            keyboardFrame.intersects(panelSourceFrame)
        let newKeyboardTop = overlapsPanel
            ? keyboardFrame.minY
            : panelSourceFrame.maxY

        withAnimation(
            keyboardAnimation(
                from: notification,
                duration: duration
            )
        ) {
            keyboardTop = newKeyboardTop
        }
    }

    private func keyboardAnimation(
        from notification: Notification,
        duration: Double
    ) -> Animation {
        let rawCurve = (
            notification.userInfo?[
                UIResponder.keyboardAnimationCurveUserInfoKey
            ] as? NSNumber
        )?.intValue
        let curve = rawCurve.flatMap(UIView.AnimationCurve.init)

        switch curve {
        case .easeInOut:
            return Animation.timingCurve(
                0.42,
                0,
                0.58,
                1,
                duration: duration
            )
        case .easeIn:
            return Animation.timingCurve(
                0.42,
                0,
                1,
                1,
                duration: duration
            )
        case .linear:
            return Animation.linear(duration: duration)
        case .easeOut, .none:
            return Animation.easeOut(duration: duration)
        @unknown default:
            return Animation.easeOut(duration: duration)
        }
    }
}
