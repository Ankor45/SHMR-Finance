//
//  PieChartView+Legend.swift
//  PieChart
//
//  Created by Andrei Kovryzhenko on 31.07.2026.
//

import UIKit

extension PieChartView {
    func drawLegend(
        segments: [Segment],
        below chartRect: CGRect,
        availableWidth: CGFloat,
        context: CGContext
    ) {
        guard !segments.isEmpty else {
            return
        }

        let font = UIFont.preferredFont(forTextStyle: .caption1)
        let contentWidth = max(
            availableWidth - Constants.horizontalInset * 2,
            .zero
        )
        let rows = legendRows(
            segments: segments,
            availableWidth: contentWidth,
            font: font
        )
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.secondaryLabel,
            .paragraphStyle: paragraphStyle
        ]
        let rowHeight = max(font.lineHeight, Constants.legendMarkerSize)
        var originY = chartRect.maxY + Constants.chartToLegendSpacing

        for row in rows {
            let rowWidth = row.reduce(CGFloat.zero) { $0 + $1.width }
                + CGFloat(max(row.count - 1, .zero))
                    * Constants.legendItemSpacing
            var originX = max((availableWidth - rowWidth) / 2, .zero)

            for item in row {
                let markerRect = CGRect(
                    x: originX,
                    y: originY
                        + (rowHeight - Constants.legendMarkerSize) / 2,
                    width: Constants.legendMarkerSize,
                    height: Constants.legendMarkerSize
                )
                context.setFillColor(item.segment.color.cgColor)
                context.fillEllipse(in: markerRect)

                let textOriginX = markerRect.maxX
                    + Constants.legendMarkerSpacing
                let textWidth = item.width
                    - Constants.legendMarkerSize
                    - Constants.legendMarkerSpacing
                (item.segment.label as NSString).draw(
                    in: CGRect(
                        x: textOriginX,
                        y: originY,
                        width: textWidth,
                        height: rowHeight
                    ),
                    withAttributes: textAttributes
                )
                originX += item.width + Constants.legendItemSpacing
            }

            originY += rowHeight + Constants.legendRowSpacing
        }
    }

    func legendRows(
        segments: [Segment],
        availableWidth: CGFloat,
        font: UIFont
    ) -> [[LegendItem]] {
        guard availableWidth > .zero else {
            return []
        }

        let items = segments.map { segment in
            let textWidth = ceil(
                (segment.label as NSString).size(
                    withAttributes: [.font: font]
                ).width
            )
            let width = min(
                Constants.legendMarkerSize
                    + Constants.legendMarkerSpacing
                    + textWidth,
                availableWidth
            )
            return LegendItem(segment: segment, width: width)
        }
        var rows: [[LegendItem]] = []
        var currentRow: [LegendItem] = []
        var currentWidth = CGFloat.zero

        for item in items {
            let spacing = currentRow.isEmpty
                ? .zero
                : Constants.legendItemSpacing
            if !currentRow.isEmpty,
               currentWidth + spacing + item.width > availableWidth {
                rows.append(currentRow)
                currentRow = []
                currentWidth = .zero
            }

            let itemSpacing = currentRow.isEmpty
                ? .zero
                : Constants.legendItemSpacing
            currentRow.append(item)
            currentWidth += itemSpacing + item.width
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        return rows
    }

    func preferredHeight(for width: CGFloat) -> CGFloat {
        let chartDiameter = resolvedChartDiameter(for: width)
        let segments = displaySegments
        guard !segments.isEmpty else {
            return Constants.chartTopInset
                + chartDiameter
                + Constants.bottomInset
        }

        let font = UIFont.preferredFont(forTextStyle: .caption1)
        let rows = legendRows(
            segments: segments,
            availableWidth: max(
                width - Constants.horizontalInset * 2,
                .zero
            ),
            font: font
        )
        let rowHeight = max(font.lineHeight, Constants.legendMarkerSize)
        let legendHeight = CGFloat(rows.count) * rowHeight
            + CGFloat(max(rows.count - 1, .zero))
                * Constants.legendRowSpacing

        return Constants.chartTopInset
            + chartDiameter
            + Constants.chartToLegendSpacing
            + legendHeight
            + Constants.bottomInset
    }

    func resolvedWidth(for proposedWidth: CGFloat) -> CGFloat {
        guard proposedWidth.isFinite, proposedWidth > .zero else {
            return Constants.maximumChartDiameter
                + Constants.horizontalInset * 2
        }
        return proposedWidth
    }
}
