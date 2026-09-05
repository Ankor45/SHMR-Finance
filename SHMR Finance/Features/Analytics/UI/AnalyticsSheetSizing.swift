//
//  AnalyticsSheetSizing.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import UIKit

@MainActor
protocol AnalyticsSheetHeightProviding: AnyObject {
    func resolvedSheetHeight(
        containerWidth: CGFloat,
        bottomSafeAreaInset: CGFloat,
        maximumHeight: CGFloat
    ) -> CGFloat
}

protocol AnalyticsStandardFilterSheetHeightProviding:
    AnalyticsSheetHeightProviding {}

enum AnalyticsFilterSheetMetrics {
    static let headerHeight: CGFloat = 72
    static let rowHeight: CGFloat = 60
    static let visibleRowCount = 5

    static func resolvedHeight(
        bottomSafeAreaInset: CGFloat,
        maximumHeight: CGFloat
    ) -> CGFloat {
        let contentHeight = headerHeight
            + CGFloat(visibleRowCount) * rowHeight
            + bottomSafeAreaInset
        return min(ceil(contentHeight), maximumHeight)
    }
}

extension AnalyticsStandardFilterSheetHeightProviding {
    func resolvedSheetHeight(
        containerWidth: CGFloat,
        bottomSafeAreaInset: CGFloat,
        maximumHeight: CGFloat
    ) -> CGFloat {
        AnalyticsFilterSheetMetrics.resolvedHeight(
            bottomSafeAreaInset: bottomSafeAreaInset,
            maximumHeight: maximumHeight
        )
    }
}
