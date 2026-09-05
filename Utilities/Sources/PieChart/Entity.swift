//
//  Entity.swift
//  PieChart
//
//  Created by Andrei Kovryzhenko on 31.07.2026.
//

import Foundation

public struct Entity: Equatable, Sendable {
    /// Non-positive values are excluded from the chart.
    public let value: Decimal
    public let label: String

    public init(value: Decimal, label: String) {
        self.value = value
        self.label = label
    }
}
