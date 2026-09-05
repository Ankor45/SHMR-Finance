//
//  AnalyticsViewState.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import Foundation

enum AnalyticsLoadState: Equatable {
    case loading
    case loaded
    case failed(String)
}

struct AnalyticsViewState {
    let filters: AnalyticsFilterState
    let transactions: [Transaction]
    let loadState: AnalyticsLoadState
    let totalAmount: Decimal
    let currencyCode: String
    let selectedCategoryNames: [String]
    let selectedAccountName: String?
    let chartItems: [AnalyticsChartItem]
}

struct AnalyticsChartItem {
    let value: Decimal
    let label: String
}
