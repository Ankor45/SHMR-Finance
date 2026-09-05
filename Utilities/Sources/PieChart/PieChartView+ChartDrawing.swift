//
//  PieChartView+ChartDrawing.swift
//  PieChart
//
//  Created by Andrei Kovryzhenko on 31.07.2026.
//

import UIKit

extension PieChartView {
    func drawChart(
        segments: [Segment],
        in rect: CGRect,
        context: CGContext
    ) {
        let lineWidth = max(
            rect.width * Constants.lineWidthRatio,
            Constants.minimumLineWidth
        )
        let radius = max((rect.width - lineWidth) / 2, .zero)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        context.setLineWidth(lineWidth)
        context.setLineCap(.butt)

        let totalValue = segments.reduce(CGFloat.zero) {
            $0 + $1.scalarValue
        }
        guard totalValue > .zero else {
            drawEmptyTrack(in: context, center: center, radius: radius)
            return
        }

        var currentAngle = Constants.startAngle
        for segment in segments {
            let endAngle = currentAngle
                + Constants.fullCircle * segment.scalarValue / totalValue
            context.setStrokeColor(segment.color.cgColor)
            context.addArc(
                center: center,
                radius: radius,
                startAngle: currentAngle,
                endAngle: endAngle,
                clockwise: false
            )
            context.strokePath()
            currentAngle = endAngle
        }
    }

    func drawCenterText(in chartRect: CGRect) {
        drawCenterText(
            in: chartRect,
            title: centerTitle,
            amount: displayedTotalText
        )
    }

    func drawCenterText(
        in chartRect: CGRect,
        title: String,
        amount: String
    ) {
        let lineWidth = max(
            chartRect.width * Constants.lineWidthRatio,
            Constants.minimumLineWidth
        )
        let contentWidth = max(
            chartRect.width
                - lineWidth * 2
                - Constants.centerTextHorizontalInset * 2,
            .zero
        )
        let titleFont = fittedFont(
            for: title,
            baseFont: UIFont.systemFont(
                ofSize: Constants.centerTitleFontSize,
                weight: .medium
            ),
            textStyle: .subheadline,
            availableWidth: contentWidth
        )
        let amountFont = fittedFont(
            for: amount,
            baseFont: UIFont.systemFont(
                ofSize: Constants.amountFontSize,
                weight: .bold
            ),
            textStyle: .title2,
            availableWidth: contentWidth
        )
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byTruncatingTail
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle
        ]
        let amountAttributes: [NSAttributedString.Key: Any] = [
            .font: amountFont,
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle
        ]
        let contentHeight = titleFont.lineHeight
            + Constants.centerTextSpacing
            + amountFont.lineHeight
        let titleRect = CGRect(
            x: chartRect.midX - contentWidth / 2,
            y: chartRect.midY - contentHeight / 2,
            width: contentWidth,
            height: titleFont.lineHeight
        )
        let amountRect = CGRect(
            x: chartRect.midX - contentWidth / 2,
            y: titleRect.maxY + Constants.centerTextSpacing,
            width: contentWidth,
            height: amountFont.lineHeight
        )
        (title as NSString).draw(
            in: titleRect,
            withAttributes: titleAttributes
        )
        (amount as NSString).draw(
            in: amountRect,
            withAttributes: amountAttributes
        )
    }

    private func fittedFont(
        for text: String,
        baseFont: UIFont,
        textStyle: UIFont.TextStyle,
        availableWidth: CGFloat
    ) -> UIFont {
        let maximumFont = UIFontMetrics(forTextStyle: textStyle).scaledFont(
            for: baseFont
        )
        let textWidth = (text as NSString).size(
            withAttributes: [.font: maximumFont]
        ).width

        guard
            availableWidth > .zero,
            textWidth > availableWidth,
            textWidth > .zero
        else {
            return maximumFont
        }

        return UIFont(
            descriptor: maximumFont.fontDescriptor,
            size: maximumFont.pointSize * availableWidth / textWidth
        )
    }

    func chartRect(in rect: CGRect) -> CGRect {
        let diameter = resolvedChartDiameter(for: rect.width)
        return CGRect(
            x: rect.midX - diameter / 2,
            y: rect.minY + Constants.chartTopInset,
            width: diameter,
            height: diameter
        )
    }

    func resolvedChartDiameter(for width: CGFloat) -> CGFloat {
        min(
            max(width - Constants.horizontalInset * 2, .zero),
            Constants.maximumChartDiameter
        )
    }

    private func drawEmptyTrack(
        in context: CGContext,
        center: CGPoint,
        radius: CGFloat
    ) {
        context.setStrokeColor(Constants.emptyTrackColor.cgColor)
        context.addArc(
            center: center,
            radius: radius,
            startAngle: Constants.startAngle,
            endAngle: Constants.startAngle + Constants.fullCircle,
            clockwise: false
        )
        context.strokePath()
    }
}
