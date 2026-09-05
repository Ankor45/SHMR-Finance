//
//  NativePasteMenuView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import SwiftUI
import UIKit

private enum Constants {
    static let longPressDuration: TimeInterval = 0.25
    static let menuAnchorY: CGFloat = -36
}

struct NativePasteMenuView: UIViewRepresentable {
    // MARK: - Properties

    let isEnabled: Bool
    let onTap: () -> Void
    let onPaste: (String) -> Void

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> NativePasteInteractionView {
        NativePasteInteractionView(
            isEnabled: isEnabled,
            onTap: onTap,
            onPaste: onPaste
        )
    }

    func updateUIView(
        _ view: NativePasteInteractionView,
        context: Context
    ) {
        view.isInteractionEnabled = isEnabled
        view.onTap = onTap
        view.onPaste = onPaste
    }
}

final class NativePasteInteractionView: UIView {
    // MARK: - Properties

    var isInteractionEnabled: Bool
    var onTap: () -> Void
    var onPaste: (String) -> Void

    private lazy var editMenuInteraction = UIEditMenuInteraction(
        delegate: nil
    )

    override var canBecomeFirstResponder: Bool {
        true
    }

    // MARK: - Initializers

    init(
        isEnabled: Bool,
        onTap: @escaping () -> Void,
        onPaste: @escaping (String) -> Void
    ) {
        isInteractionEnabled = isEnabled
        self.onTap = onTap
        self.onPaste = onPaste
        super.init(frame: .zero)

        configureView()
        configureInteractions()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIResponder

    override func canPerformAction(
        _ action: Selector,
        withSender sender: Any?
    ) -> Bool {
        guard isInteractionEnabled else {
            return false
        }

        if action == #selector(paste(_:)) {
            return UIPasteboard.general.hasStrings
        }

        return false
    }

    override func paste(_ sender: Any?) {
        guard
            isInteractionEnabled,
            let clipboardText = UIPasteboard.general.string
        else {
            return
        }

        onPaste(clipboardText)
    }

    // MARK: - Private Methods

    private func configureView() {
        backgroundColor = .clear
        isAccessibilityElement = false
        pasteConfiguration = UIPasteConfiguration(
            forAccepting: String.self
        )
    }

    private func configureInteractions() {
        addInteraction(editMenuInteraction)

        let longPressRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(_:))
        )
        longPressRecognizer.minimumPressDuration =
            Constants.longPressDuration
        longPressRecognizer.allowedTouchTypes = [
            NSNumber(value: UITouch.TouchType.direct.rawValue)
        ]

        let tapRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTap)
        )
        tapRecognizer.require(toFail: longPressRecognizer)

        addGestureRecognizer(longPressRecognizer)
        addGestureRecognizer(tapRecognizer)
    }

    @objc
    private func handleTap() {
        guard isInteractionEnabled else {
            return
        }

        onTap()
    }

    @objc
    private func handleLongPress(
        _ recognizer: UILongPressGestureRecognizer
    ) {
        guard
            isInteractionEnabled,
            recognizer.state == .began,
            becomeFirstResponder()
        else {
            return
        }

        let configuration = UIEditMenuConfiguration(
            identifier: nil,
            sourcePoint: CGPoint(
                x: bounds.midX,
                y: bounds.minY + Constants.menuAnchorY
            )
        )
        editMenuInteraction.presentEditMenu(with: configuration)
    }
}
