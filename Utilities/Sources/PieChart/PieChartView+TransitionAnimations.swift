//
//  PieChartView+TransitionAnimations.swift
//  PieChart
//
//  Created by Andrei Kovryzhenko on 04.08.2026.
//

import UIKit

extension PieChartView {
    func addTransitionAnimations(
        to transitionLayers: ContentTransitionLayers
    ) {
        addRotatingFadeAnimation(
            to: transitionLayers.sourceRing,
            isSource: true
        )
        addRotatingFadeAnimation(
            to: transitionLayers.destinationRing,
            isSource: false
        )
        addFadeAnimation(
            to: transitionLayers.sourceSupplementary,
            isSource: true
        )
        addFadeAnimation(
            to: transitionLayers.destinationSupplementary,
            isSource: false
        )
        addSegmentRevealAnimations(to: transitionLayers.destinationRing)
    }
}

private extension PieChartView {
    enum TransitionTimeline {
        static let sourceOpacityValues: [CGFloat] = [1, 1, .zero, .zero]
        static let destinationOpacityValues: [CGFloat] = [
            .zero,
            .zero,
            1,
            1
        ]
        static let sourceOpacityKeyTimes: [NSNumber] = [0, 0.1, 0.48, 1]
        static let destinationOpacityKeyTimes: [NSNumber] = [
            0,
            0.52,
            0.9,
            1
        ]
        static let movementKeyTimes: [NSNumber] = [0, 0.5, 1]
    }

    func addRotatingFadeAnimation(
        to targetLayer: CALayer,
        isSource: Bool
    ) {
        let halfTurn = CGFloat.pi
        let fullTurn = Constants.fullCircle
        let rotationValues = isSource
            ? [CGFloat.zero, halfTurn, halfTurn]
            : [halfTurn, halfTurn, fullTurn]
        let opacityValues = opacityValues(isSource: isSource)

        targetLayer.transform = CATransform3DMakeRotation(
            rotationValues[2],
            .zero,
            .zero,
            1
        )
        targetLayer.opacity = Float(opacityValues[3])

        let rotationAnimation = keyframeAnimation(
            keyPath: "transform.rotation.z",
            values: rotationValues
        )
        let opacityAnimation = opacityAnimation(
            values: opacityValues,
            keyTimes: opacityKeyTimes(isSource: isSource)
        )
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [
            rotationAnimation,
            opacityAnimation
        ]
        configureTransitionAnimation(animationGroup)
        targetLayer.add(
            animationGroup,
            forKey: Constants.contentTransitionAnimationKey
        )
    }

    func addFadeAnimation(
        to targetLayer: CALayer,
        isSource: Bool
    ) {
        let opacityValues = opacityValues(isSource: isSource)
        targetLayer.opacity = Float(opacityValues[3])

        let animation = opacityAnimation(
            values: opacityValues,
            keyTimes: opacityKeyTimes(isSource: isSource)
        )
        configureTransitionAnimation(animation)
        targetLayer.add(
            animation,
            forKey: Constants.contentTransitionAnimationKey
        )
    }

    func addSegmentRevealAnimations(to ringLayer: CALayer) {
        for case let shapeLayer as CAShapeLayer in
            (ringLayer.sublayers ?? []).dropFirst() {
            let startAnimation = keyframeAnimation(
                keyPath: "strokeStart",
                values: [
                    CGFloat.zero,
                    CGFloat.zero,
                    shapeLayer.strokeStart
                ]
            )
            let endAnimation = keyframeAnimation(
                keyPath: "strokeEnd",
                values: [
                    CGFloat.zero,
                    CGFloat.zero,
                    shapeLayer.strokeEnd
                ]
            )
            let animationGroup = CAAnimationGroup()
            animationGroup.animations = [
                startAnimation,
                endAnimation
            ]
            configureTransitionAnimation(animationGroup)
            shapeLayer.add(
                animationGroup,
                forKey: Constants.segmentRevealAnimationKey
            )
        }
    }

    func keyframeAnimation(
        keyPath: String,
        values: [CGFloat]
    ) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: keyPath)
        animation.values = values
        animation.keyTimes = TransitionTimeline.movementKeyTimes
        animation.timingFunctions = [
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]
        animation.duration = Constants.contentAnimationDuration
        return animation
    }

    func opacityAnimation(
        values: [CGFloat],
        keyTimes: [NSNumber]
    ) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.values = values
        animation.keyTimes = keyTimes
        animation.duration = Constants.contentAnimationDuration
        animation.timingFunctions = Array(
            repeating: CAMediaTimingFunction(name: .easeInEaseOut),
            count: max(values.count - 1, .zero)
        )
        return animation
    }

    func opacityValues(isSource: Bool) -> [CGFloat] {
        isSource
            ? TransitionTimeline.sourceOpacityValues
            : TransitionTimeline.destinationOpacityValues
    }

    func opacityKeyTimes(isSource: Bool) -> [NSNumber] {
        isSource
            ? TransitionTimeline.sourceOpacityKeyTimes
            : TransitionTimeline.destinationOpacityKeyTimes
    }

    func configureTransitionAnimation(_ animation: CAAnimation) {
        if animation.duration == .zero {
            animation.duration = Constants.contentAnimationDuration
        }
        animation.fillMode = .both
        animation.isRemovedOnCompletion = false
    }
}
