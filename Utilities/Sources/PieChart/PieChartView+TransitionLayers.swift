//
//  PieChartView+TransitionLayers.swift
//  PieChart
//
//  Created by Andrei Kovryzhenko on 04.08.2026.
//

import UIKit

extension PieChartView {
    func makeContentTransitionLayers(
        source: ContentSnapshot,
        destination: ContentSnapshot
    ) -> ContentTransitionLayers {
        let container = CALayer()
        container.frame = bounds
        container.contentsScale = traitCollection.displayScale

        let sourceRing = makeRingTransitionLayer(
            segments: source.segments
        )
        let destinationRing = makeRingTransitionLayer(
            segments: destination.segments
        )
        let transitionLayers = ContentTransitionLayers(
            container: container,
            sourceRing: sourceRing,
            destinationRing: destinationRing,
            sourceSupplementary: makeSupplementaryLayer(),
            destinationSupplementary: makeSupplementaryLayer()
        )

        container.addSublayer(sourceRing)
        container.addSublayer(destinationRing)
        container.addSublayer(transitionLayers.sourceSupplementary)
        container.addSublayer(transitionLayers.destinationSupplementary)
        updateContentTransitionLayers(
            transitionLayers,
            source: source,
            destination: destination
        )
        return transitionLayers
    }

    func updateContentTransitionLayers(
        _ transitionLayers: ContentTransitionLayers,
        source: ContentSnapshot,
        destination: ContentSnapshot
    ) {
        transitionLayers.container.frame = bounds
        guard transitionLayers.renderedSize != bounds.size else {
            return
        }

        transitionLayers.renderedSize = bounds.size
        let contentBounds = transitionLayers.container.bounds
        let chartFrame = chartRect(in: contentBounds)
        let layerBounds = CGRect(origin: .zero, size: chartFrame.size)
        let layerPosition = CGPoint(
            x: chartFrame.midX,
            y: chartFrame.midY
        )

        for ringLayer in [
            transitionLayers.sourceRing,
            transitionLayers.destinationRing
        ] {
            ringLayer.bounds = layerBounds
            ringLayer.position = layerPosition
            updatePaths(in: ringLayer)
        }

        updateSupplementaryLayer(
            transitionLayers.sourceSupplementary,
            contentBounds: contentBounds,
            content: source
        )
        updateSupplementaryLayer(
            transitionLayers.destinationSupplementary,
            contentBounds: contentBounds,
            content: destination
        )
    }
}

private extension PieChartView {
    func makeRingTransitionLayer(segments: [Segment]) -> CALayer {
        let containerLayer = CALayer()
        containerLayer.contentsScale = traitCollection.displayScale

        let trackLayer = makeRingLayer(
            color: Constants.emptyTrackColor,
            start: .zero,
            end: 1
        )
        containerLayer.addSublayer(trackLayer)

        let totalValue = segments.reduce(CGFloat.zero) {
            $0 + $1.scalarValue
        }
        guard totalValue > .zero else {
            return containerLayer
        }

        var currentPosition = CGFloat.zero
        for segment in segments {
            let startPosition = currentPosition
            currentPosition += segment.scalarValue / totalValue
            containerLayer.addSublayer(
                makeRingLayer(
                    color: segment.color,
                    start: startPosition,
                    end: currentPosition
                )
            )
        }
        return containerLayer
    }

    func makeRingLayer(
        color: UIColor,
        start: CGFloat,
        end: CGFloat
    ) -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = nil
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineCap = .butt
        shapeLayer.strokeStart = start
        shapeLayer.strokeEnd = end
        shapeLayer.contentsScale = traitCollection.displayScale
        return shapeLayer
    }

    func makeSupplementaryLayer() -> CALayer {
        let supplementaryLayer = CALayer()
        supplementaryLayer.contentsScale = traitCollection.displayScale
        supplementaryLayer.contentsGravity = .resize
        return supplementaryLayer
    }

    func updateSupplementaryLayer(
        _ supplementaryLayer: CALayer,
        contentBounds: CGRect,
        content: ContentSnapshot
    ) {
        supplementaryLayer.frame = contentBounds
        supplementaryLayer.contents = supplementaryImage(
            for: content,
            in: contentBounds
        )?.cgImage
    }

    func supplementaryImage(
        for content: ContentSnapshot,
        in contentBounds: CGRect
    ) -> UIImage? {
        guard contentBounds.width > .zero, contentBounds.height > .zero else {
            return nil
        }

        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = false
        format.scale = traitCollection.displayScale
        let renderer = UIGraphicsImageRenderer(
            size: contentBounds.size,
            format: format
        )

        return renderer.image { rendererContext in
            let chartFrame = chartRect(in: contentBounds)
            if !content.hidesCenterContent {
                drawCenterText(
                    in: chartFrame,
                    title: content.centerTitle,
                    amount: content.totalText
                )
            }
            drawLegend(
                segments: content.segments,
                below: chartFrame,
                availableWidth: contentBounds.width,
                context: rendererContext.cgContext
            )
        }
    }

    func updatePaths(in containerLayer: CALayer) {
        let lineWidth = max(
            containerLayer.bounds.width * Constants.lineWidthRatio,
            Constants.minimumLineWidth
        )
        let center = CGPoint(
            x: containerLayer.bounds.midX,
            y: containerLayer.bounds.midY
        )
        let radius = max(
            (containerLayer.bounds.width - lineWidth) / 2,
            .zero
        )
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: Constants.startAngle,
            endAngle: Constants.startAngle + Constants.fullCircle,
            clockwise: true
        ).cgPath

        for case let shapeLayer as CAShapeLayer in
            containerLayer.sublayers ?? [] {
            shapeLayer.frame = containerLayer.bounds
            shapeLayer.lineWidth = lineWidth
            shapeLayer.path = path
        }
    }
}
