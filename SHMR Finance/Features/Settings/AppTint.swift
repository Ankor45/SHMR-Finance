//
//  AppTint.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 05.08.2026.
//

import SwiftUI
import UIKit

enum AppTint: String, CaseIterable, Identifiable {
    case blue
    case green
    case purple
    case orange
    case pink

    var id: Self { self }

    var accessibilityLabel: String {
        switch self {
        case .blue:
            AppLocalization.string(localized: "Синий")
        case .green:
            AppLocalization.string(localized: "Зелёный")
        case .purple:
            AppLocalization.string(localized: "Фиолетовый")
        case .orange:
            AppLocalization.string(localized: "Оранжевый")
        case .pink:
            AppLocalization.string(localized: "Розовый")
        }
    }

    var color: Color {
        Color(uiColor: uiColor)
    }

    var uiColor: UIColor {
        switch self {
        case .blue:
            UIColor(named: "AccentColor") ?? .systemBlue
        case .green:
            .systemGreen
        case .purple:
            .systemPurple
        case .orange:
            .systemOrange
        case .pink:
            .systemPink
        }
    }
}
