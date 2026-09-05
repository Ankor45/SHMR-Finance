//
//  AppTab.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 18.07.2026.
//

import Foundation

enum AppTab: Hashable, CaseIterable, Identifiable {
    case expenses
    case income
    case accounts

    var id: Self { self }

    var title: String {
        switch self {
        case .expenses:
            AppLocalization.string(localized: "Расходы")
        case .income:
            AppLocalization.string(localized: "Доходы")
        case .accounts:
            AppLocalization.string(localized: "Счета")
        }
    }

    var iconName: String {
        switch self {
        case .expenses:
            "arrow.down.circle"
        case .income:
            "arrow.up.circle"
        case .accounts:
            "wallet.bifold"
        }
    }
}
