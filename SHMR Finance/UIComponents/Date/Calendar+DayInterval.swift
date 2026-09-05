//
//  Calendar+DayInterval.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 31.07.2026.
//

import Foundation

private enum Constants {
    static let inclusiveEndOffset: TimeInterval = 0.001
}

extension Calendar {
    func inclusiveDayInterval(
        from startDate: Date,
        through endDate: Date
    ) -> DateInterval? {
        let start = startOfDay(for: startDate)
        let end = startOfDay(for: endDate)
        guard let dayAfterEnd = date(
            byAdding: .day,
            value: 1,
            to: end
        ) else {
            return nil
        }

        return DateInterval(
            start: start,
            end: dayAfterEnd.addingTimeInterval(-Constants.inclusiveEndOffset)
        )
    }
}
