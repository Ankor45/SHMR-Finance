//
//  PieChartView+Animation.swift
//  PieChart
//
//  Created by Andrei Kovryzhenko on 31.07.2026.
//

import UIKit

public extension PieChartView {
    @discardableResult
    func setContent(
        entities newEntities: [Entity],
        totalText newTotalText: String?,
        centerTitle newCenterTitle: String? = nil,
        hidesCenterContent: Bool = false,
        animated: Bool
    ) -> Bool {
        let resolvedCenterTitle = newCenterTitle ?? centerTitle
        guard
            entities != newEntities
                || totalText != newTotalText
                || centerTitle != resolvedCenterTitle
                || self.hidesCenterContent != hidesCenterContent
        else {
            return isContentTransitionActive
        }

        let sourceContent = contentSnapshot
        let wasTransitionActive = isContentTransitionActive
        let shouldAnimate = animated
            && !wasTransitionActive
            && !UIAccessibility.isReduceMotionEnabled
            && (
                !sourceContent.segments.isEmpty
                    || newEntities.contains { $0.value > .zero }
            )

        contentAnimationGeneration &+= 1
        let generation = contentAnimationGeneration
        resetContentTransition(redraw: false)

        self.hidesCenterContent = hidesCenterContent
        isContentTransitionActive = shouldAnimate
        transitionSourceContent = shouldAnimate ? sourceContent : nil
        applyContent(
            entities: newEntities,
            totalText: newTotalText,
            centerTitle: resolvedCenterTitle
        )
        transitionDestinationContent = shouldAnimate
            ? contentSnapshot
            : nil

        guard
            shouldAnimate,
            window != nil,
            bounds.width > .zero
        else {
            return shouldAnimate
        }

        animateContentTransition(generation: generation)
        return true
    }
}

extension PieChartView {
    func animateContentTransition(generation: Int) {
        guard
            let sourceContent = transitionSourceContent,
            let destinationContent = transitionDestinationContent
        else {
            resetContentTransition()
            return
        }

        let transitionLayers = makeContentTransitionLayers(
            source: sourceContent,
            destination: destinationContent
        )
        contentTransitionLayers = transitionLayers
        layer.addSublayer(transitionLayers.container)
        setNeedsDisplay()
        layer.displayIfNeeded()

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.finishContentAnimation(generation: generation)
        }
        addTransitionAnimations(to: transitionLayers)
        CATransaction.commit()
    }

    func updateContentTransitionLayout() {
        guard
            let transitionLayers = contentTransitionLayers,
            let sourceContent = transitionSourceContent,
            let destinationContent = transitionDestinationContent
        else {
            return
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updateContentTransitionLayers(
            transitionLayers,
            source: sourceContent,
            destination: destinationContent
        )
        CATransaction.commit()
    }

    func cancelContentAnimation() {
        contentAnimationGeneration &+= 1
        resetContentTransition(notifiesCompletion: true)
    }
}

private extension PieChartView {
    var contentSnapshot: ContentSnapshot {
        ContentSnapshot(
            segments: displaySegments,
            centerTitle: centerTitle,
            totalText: displayedTotalText,
            hidesCenterContent: hidesCenterContent
        )
    }

    func applyContent(
        entities newEntities: [Entity],
        totalText newTotalText: String?,
        centerTitle newCenterTitle: String
    ) {
        isApplyingContent = true
        entities = newEntities
        totalText = newTotalText
        centerTitle = newCenterTitle
        isApplyingContent = false
        contentDidChange()
        layer.displayIfNeeded()
    }

    func finishContentAnimation(generation: Int) {
        guard contentAnimationGeneration == generation else {
            return
        }

        resetContentTransition(notifiesCompletion: true)
    }

    func resetContentTransition(
        redraw: Bool = true,
        notifiesCompletion: Bool = false
    ) {
        let wasTransitionActive = isContentTransitionActive
        if let container = contentTransitionLayers?.container {
            removeAnimationsRecursively(from: container)
        }
        contentTransitionLayers?.container.removeFromSuperlayer()
        contentTransitionLayers = nil
        transitionSourceContent = nil
        transitionDestinationContent = nil
        isContentTransitionActive = false
        if redraw {
            setNeedsDisplay()
            layer.displayIfNeeded()
        }
        if notifiesCompletion, wasTransitionActive {
            onContentTransitionCompletion?()
        }
    }

    func removeAnimationsRecursively(from targetLayer: CALayer) {
        targetLayer.sublayers?.forEach(removeAnimationsRecursively)
        targetLayer.removeAllAnimations()
    }
}
