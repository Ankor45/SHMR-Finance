//
//  HapticsService.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 05.08.2026.
//

import Observation
import UIKit

private enum Constants {
    static let isEnabledStorageKey = "isHapticsEnabled"
}

@MainActor
@Observable
final class HapticsService {
    // MARK: - Public Properties

    var isEnabled: Bool {
        didSet {
            userDefaults.set(
                isEnabled,
                forKey: Constants.isEnabledStorageKey
            )
        }
    }

    // MARK: - Private Properties

    private let userDefaults: UserDefaults
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let keyPressGenerator = UIImpactFeedbackGenerator(style: .light)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    // MARK: - Initializers

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        isEnabled = userDefaults.object(
            forKey: Constants.isEnabledStorageKey
        ) as? Bool ?? true
    }

    // MARK: - Public Methods

    func selectionChanged() {
        guard isEnabled else {
            return
        }

        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    func impactOccurred() {
        guard isEnabled else {
            return
        }

        impactGenerator.impactOccurred()
        impactGenerator.prepare()
    }

    func keyPressOccurred() {
        guard isEnabled else {
            return
        }

        keyPressGenerator.impactOccurred()
        keyPressGenerator.prepare()
    }

    func successOccurred() {
        guard isEnabled else {
            return
        }

        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
}
