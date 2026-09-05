//
//  AppTheme.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 05.08.2026.
//

import SwiftUI
import UIKit

enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: Self { self }

    var title: String {
        switch self {
        case .system:
            AppLocalization.string(localized: "Системная")
        case .light:
            AppLocalization.string(localized: "Светлая")
        case .dark:
            AppLocalization.string(localized: "Тёмная")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system:
            .unspecified
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
