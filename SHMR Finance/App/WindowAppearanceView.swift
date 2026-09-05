//
//  WindowAppearanceView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 05.08.2026.
//

import SwiftUI
import UIKit

struct WindowAppearanceView: UIViewRepresentable {
    let interfaceStyle: UIUserInterfaceStyle
    let tintColor: UIColor
    let isPrivacyProtectionEnabled: Bool

    func makeUIView(context: Context) -> WindowAppearanceHostingView {
        WindowAppearanceHostingView(
            interfaceStyle: interfaceStyle,
            applicationTintColor: tintColor,
            isPrivacyProtectionEnabled: isPrivacyProtectionEnabled
        )
    }

    func updateUIView(
        _ uiView: WindowAppearanceHostingView,
        context: Context
    ) {
        uiView.update(
            interfaceStyle: interfaceStyle,
            applicationTintColor: tintColor,
            isPrivacyProtectionEnabled: isPrivacyProtectionEnabled
        )
    }

    static func dismantleUIView(
        _ uiView: WindowAppearanceHostingView,
        coordinator: Void
    ) {
        uiView.removePrivacyProtection()
    }
}

final class WindowAppearanceHostingView: UIView {
    private var interfaceStyle: UIUserInterfaceStyle
    private var applicationTintColor: UIColor
    private var isPrivacyProtectionEnabled: Bool
    private weak var privacyProtectionView: UIVisualEffectView?

    init(
        interfaceStyle: UIUserInterfaceStyle,
        applicationTintColor: UIColor,
        isPrivacyProtectionEnabled: Bool
    ) {
        self.interfaceStyle = interfaceStyle
        self.applicationTintColor = applicationTintColor
        self.isPrivacyProtectionEnabled = isPrivacyProtectionEnabled
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyAppearance()
        updatePrivacyProtection()
    }

    func update(
        interfaceStyle: UIUserInterfaceStyle,
        applicationTintColor: UIColor,
        isPrivacyProtectionEnabled: Bool
    ) {
        let appearanceChanged =
            self.interfaceStyle != interfaceStyle
                || !self.applicationTintColor.isEqual(applicationTintColor)
        let privacyProtectionChanged =
            self.isPrivacyProtectionEnabled
                != isPrivacyProtectionEnabled

        self.interfaceStyle = interfaceStyle
        self.applicationTintColor = applicationTintColor
        self.isPrivacyProtectionEnabled = isPrivacyProtectionEnabled

        if appearanceChanged {
            applyAppearance()
        }

        if privacyProtectionChanged || isPrivacyProtectionEnabled {
            updatePrivacyProtection()
        }
    }

    func removePrivacyProtection() {
        privacyProtectionView?.removeFromSuperview()
    }

    private func applyAppearance() {
        window?.overrideUserInterfaceStyle = interfaceStyle
        window?.tintColor = applicationTintColor
    }

    private func updatePrivacyProtection() {
        guard isPrivacyProtectionEnabled else {
            removePrivacyProtection()
            return
        }

        guard let window else {
            return
        }

        if let privacyProtectionView {
            window.bringSubviewToFront(privacyProtectionView)
            return
        }

        let privacyProtectionView = UIVisualEffectView(
            effect: UIBlurEffect(style: .systemMaterial)
        )
        privacyProtectionView.frame = window.bounds
        privacyProtectionView.autoresizingMask = [
            .flexibleWidth,
            .flexibleHeight
        ]
        privacyProtectionView.isUserInteractionEnabled = true
        privacyProtectionView.accessibilityElementsHidden = true

        window.addSubview(privacyProtectionView)
        self.privacyProtectionView = privacyProtectionView
    }
}
