//
//  PieChartView.swift
//  PieChart
//
//  Created by Andrei Kovryzhenko on 31.07.2026.
//

import UIKit

public final class PieChartView: UIView {
    enum Constants {
        static let defaultCenterTitle = "Всего за период"
        static let defaultOtherSegmentLabel = "Другое"
        static let maximumIndividualSegmentCount = 5
        static let startAngle = -CGFloat.pi / 2
        static let fullCircle = CGFloat.pi * 2
        static let lineWidthRatio: CGFloat = 0.12
        static let minimumLineWidth: CGFloat = 1
        static let horizontalInset: CGFloat = 16
        static let chartTopInset: CGFloat = 8
        static let maximumChartDiameter: CGFloat = 260
        static let chartToLegendSpacing: CGFloat = 20
        static let legendRowSpacing: CGFloat = 8
        static let legendItemSpacing: CGFloat = 16
        static let legendMarkerSpacing: CGFloat = 6
        static let legendMarkerSize: CGFloat = 10
        static let bottomInset: CGFloat = 8
        static let centerTextSpacing: CGFloat = 4
        static let centerTextHorizontalInset: CGFloat = 12
        static let centerTitleFontSize: CGFloat = 15
        static let amountFontSize: CGFloat = 28
        static let contentAnimationDuration: TimeInterval = 1.2
        static let contentTransitionAnimationKey =
            "PieChartContentTransition"
        static let segmentRevealAnimationKey = "PieChartSegmentReveal"
        static let amountFractionDigits = 0...2
        static let emptyTrackColor = UIColor.secondarySystemFill
        static let segmentColors: [UIColor] = [
            UIColor(red: 0.65, green: 0.53, blue: 0.97, alpha: 1),
            UIColor(red: 0.27, green: 0.79, blue: 0.87, alpha: 1),
            UIColor(red: 0.95, green: 0.52, blue: 0.68, alpha: 1),
            UIColor(red: 0.98, green: 0.72, blue: 0.38, alpha: 1),
            UIColor(red: 0.40, green: 0.72, blue: 0.52, alpha: 1),
            UIColor(red: 0.47, green: 0.57, blue: 0.78, alpha: 1)
        ]
    }

    struct Segment {
        let value: Decimal
        let scalarValue: CGFloat
        let label: String
        let color: UIColor
    }

    struct LegendItem {
        let segment: Segment
        let width: CGFloat
    }

    struct ContentSnapshot {
        let segments: [Segment]
        let centerTitle: String
        let totalText: String
        let hidesCenterContent: Bool
    }

    final class ContentTransitionLayers {
        let container: CALayer
        let sourceRing: CALayer
        let destinationRing: CALayer
        let sourceSupplementary: CALayer
        let destinationSupplementary: CALayer
        var renderedSize = CGSize.zero

        init(
            container: CALayer,
            sourceRing: CALayer,
            destinationRing: CALayer,
            sourceSupplementary: CALayer,
            destinationSupplementary: CALayer
        ) {
            self.container = container
            self.sourceRing = sourceRing
            self.destinationRing = destinationRing
            self.sourceSupplementary = sourceSupplementary
            self.destinationSupplementary = destinationSupplementary
        }
    }

    public var entities: [Entity] = [] {
        didSet { propertyDidChange() }
    }

    public var centerTitle = Constants.defaultCenterTitle {
        didSet { propertyDidChange() }
    }

    public var totalText: String? {
        didSet { propertyDidChange() }
    }

    public var otherSegmentLabel = Constants.defaultOtherSegmentLabel {
        didSet { propertyDidChange() }
    }

    public var onContentTransitionCompletion: (() -> Void)?

    var contentAnimationGeneration = 0
    var isContentTransitionActive = false
    var hidesCenterContent = false
    var isApplyingContent = false
    var contentTransitionLayers: ContentTransitionLayers?
    var transitionSourceContent: ContentSnapshot?
    var transitionDestinationContent: ContentSnapshot?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else {
            cancelContentAnimation()
            return
        }

        startPendingContentTransitionIfPossible()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateContentTransitionLayout()
        startPendingContentTransitionIfPossible()
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        let segments = displaySegments
        guard !isContentTransitionActive else {
            return
        }

        let chartFrame = chartRect(in: rect)
        drawChart(segments: segments, in: chartFrame, context: context)
        if !hidesCenterContent {
            drawCenterText(in: chartFrame)
        }
        drawLegend(
            segments: segments,
            below: chartFrame,
            availableWidth: rect.width,
            context: context
        )
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let width = resolvedWidth(for: size.width)
        return CGSize(width: width, height: preferredHeight(for: width))
    }

    public override var intrinsicContentSize: CGSize {
        let width = resolvedWidth(for: bounds.width)
        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: preferredHeight(for: width)
        )
    }

    var displaySegments: [Segment] {
        let positiveEntities = entities.filter { $0.value > .zero }
        let displayedEntities: [Entity]

        if positiveEntities.count > Constants.maximumIndividualSegmentCount {
            let individualEntities = positiveEntities.prefix(
                Constants.maximumIndividualSegmentCount
            )
            let otherValue = positiveEntities
                .dropFirst(Constants.maximumIndividualSegmentCount)
                .reduce(Decimal.zero) { $0 + $1.value }
            displayedEntities = Array(individualEntities) + [
                Entity(value: otherValue, label: otherSegmentLabel)
            ]
        } else {
            displayedEntities = positiveEntities
        }

        return displayedEntities.enumerated().compactMap { index, entity in
            let value = NSDecimalNumber(decimal: entity.value).doubleValue
            guard value.isFinite, value > .zero else {
                return nil
            }

            return Segment(
                value: entity.value,
                scalarValue: CGFloat(value),
                label: entity.label,
                color: Constants.segmentColors[
                    index % Constants.segmentColors.count
                ]
            )
        }
    }

    var total: Decimal {
        entities.reduce(.zero) { result, entity in
            entity.value > .zero ? result + entity.value : result
        }
    }

    var displayedTotalText: String {
        totalText ?? total.formatted(
            .number.precision(
                .fractionLength(Constants.amountFractionDigits)
            )
        )
    }

    private func configureView() {
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
        isAccessibilityElement = true
        registerForTraitChanges(
            [UITraitPreferredContentSizeCategory.self]
        ) { (view: PieChartView, _) in
            view.contentDidChange()
        }
        updateAccessibilityLabel()
    }

    func contentDidChange() {
        invalidateIntrinsicContentSize()
        setNeedsDisplay()
        updateAccessibilityLabel()
    }

    private func propertyDidChange() {
        guard !isApplyingContent else {
            return
        }

        contentDidChange()
    }

    private func startPendingContentTransitionIfPossible() {
        guard
            window != nil,
            bounds.width > .zero,
            isContentTransitionActive,
            contentTransitionLayers == nil
        else {
            return
        }

        contentAnimationGeneration &+= 1
        animateContentTransition(generation: contentAnimationGeneration)
    }

    private func updateAccessibilityLabel() {
        let categorySummary = displaySegments
            .map { "\($0.label), \($0.value)" }
            .joined(separator: ", ")
        accessibilityLabel = [
            centerTitle,
            displayedTotalText,
            categorySummary
        ]
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
    }
}
