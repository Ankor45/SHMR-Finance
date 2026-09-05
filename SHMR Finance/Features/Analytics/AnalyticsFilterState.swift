//
//  AnalyticsFilterState.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 29.07.2026.
//

import Foundation

enum AnalyticsSortOption: CaseIterable, Equatable {
    case date
    case amount
}

struct AnalyticsFilterState {
    var direction: Direction?
    var startDate: Date
    var endDate: Date
    var selectedCategoryIDs: Set<Int>?
    var selectedAccountID: Int?
    var sortOption: AnalyticsSortOption

    init(
        initialDirection: Direction,
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        let endDate = calendar.startOfDay(for: now)
        let monthAgo = calendar.date(
            byAdding: .month,
            value: -1,
            to: endDate
        ) ?? endDate

        direction = initialDirection
        startDate = calendar.startOfDay(for: monthAgo)
        self.endDate = endDate
        selectedCategoryIDs = nil
        selectedAccountID = nil
        sortOption = .date
    }
}
