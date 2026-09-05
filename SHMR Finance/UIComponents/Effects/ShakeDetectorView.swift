//
//  ShakeDetectorView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import SwiftUI
import UIKit

struct ShakeDetectorView: UIViewControllerRepresentable {
    // MARK: - Properties

    let onShake: () -> Void

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(
        context: Context
    ) -> ShakeDetectorViewController {
        ShakeDetectorViewController(onShake: onShake)
    }

    func updateUIViewController(
        _ viewController: ShakeDetectorViewController,
        context: Context
    ) {
        viewController.onShake = onShake
    }
}

final class ShakeDetectorViewController: UIViewController {
    // MARK: - Properties

    var onShake: () -> Void

    override var canBecomeFirstResponder: Bool {
        true
    }

    // MARK: - Initializers

    init(onShake: @escaping () -> Void) {
        self.onShake = onShake
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life Cycle

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        self.view = view
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        resignFirstResponder()
        super.viewWillDisappear(animated)
    }

    // MARK: - Motion Events

    override func motionEnded(
        _ motion: UIEvent.EventSubtype,
        with event: UIEvent?
    ) {
        super.motionEnded(motion, with: event)

        guard motion == .motionShake else {
            return
        }

        onShake()
    }
}
