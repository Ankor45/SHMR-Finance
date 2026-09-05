//
//  AnalyticsFilterFormatter.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import Foundation

private enum Constants {
    static var type: String { AppLocalization.string(localized: "Тип") }
    static var period: String { AppLocalization.string(localized: "Период") }
    static var categories: String { AppLocalization.string(localized: "Статьи") }
    static var account: String { AppLocalization.string(localized: "Счёт") }
    static var sorting: String { AppLocalization.string(localized: "Сортировка") }
    static var income: String { AppLocalization.string(localized: "Доходы") }
    static var outcome: String { AppLocalization.string(localized: "Расходы") }
    static var all: String { AppLocalization.string(localized: "Всё") }
    static var allCategories: String { AppLocalization.string(localized: "Все статьи") }
    static var noCategories: String { AppLocalization.string(localized: "Не выбраны") }
    static var allAccounts: String { AppLocalization.string(localized: "Все счета") }
    static var byDate: String { AppLocalization.string(localized: "По дате") }
    static var byAmount: String { AppLocalization.string(localized: "По сумме") }
    static let periodDateTemplate = "ddMMyyyy"
}

@MainActor
final class AnalyticsFilterFormatter {
    private lazy var periodFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = AppLocalization.locale
        formatter.calendar = .current
        formatter.setLocalizedDateFormatFromTemplate(
            Constants.periodDateTemplate
        )
        return formatter
    }()

    func title(for filter: AnalyticsFilterRow) -> String {
        switch filter {
        case .type:
            Constants.type
        case .period:
            Constants.period
        case .categories:
            Constants.categories
        case .account:
            Constants.account
        case .sorting:
            Constants.sorting
        }
    }

    func values(
        for viewState: AnalyticsViewState
    ) -> [AnalyticsFilterRow: String] {
        Dictionary(
            uniqueKeysWithValues: AnalyticsFilterRow.allCases.map {
                ($0, value(for: $0, viewState: viewState))
            }
        )
    }

    private func value(
        for filter: AnalyticsFilterRow,
        viewState: AnalyticsViewState
    ) -> String {
        switch filter {
        case .type:
            return switch viewState.filters.direction {
            case .income:
                Constants.income
            case .outcome:
                Constants.outcome
            case nil:
                Constants.all
            }
        case .period:
            let start = periodFormatter.string(
                from: viewState.filters.startDate
            )
            let end = periodFormatter.string(
                from: viewState.filters.endDate
            )
            return "\(start) – \(end)"
        case .categories:
            guard let selectedCategoryIDs = viewState.filters
                .selectedCategoryIDs else {
                return Constants.allCategories
            }
            if selectedCategoryIDs.isEmpty {
                return Constants.noCategories
            }

            return viewState.selectedCategoryNames.isEmpty
                ? String(selectedCategoryIDs.count)
                : viewState.selectedCategoryNames.joined(separator: ", ")
        case .account:
            return viewState.selectedAccountName ?? Constants.allAccounts
        case .sorting:
            return switch viewState.filters.sortOption {
            case .date:
                Constants.byDate
            case .amount:
                Constants.byAmount
            }
        }
    }
}
