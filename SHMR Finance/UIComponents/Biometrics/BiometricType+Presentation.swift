//
//  BiometricType+Presentation.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 06.08.2026.
//

import Foundation

extension BiometricType {
    var title: String {
        switch self {
        case .faceID:
            "Face ID"
        case .touchID:
            "Touch ID"
        }
    }

    var iconName: String {
        switch self {
        case .faceID:
            "faceid"
        case .touchID:
            "touchid"
        }
    }

    var usageDescription: String {
        switch self {
        case .faceID:
            AppLocalization.string(localized: "Используйте Face ID для быстрого входа")
        case .touchID:
            AppLocalization.string(
                localized: "Используйте отпечаток пальца для быстрого входа"
            )
        }
    }
}
