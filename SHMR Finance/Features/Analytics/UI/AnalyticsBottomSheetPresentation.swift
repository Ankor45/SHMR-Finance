//
//  AnalyticsBottomSheetPresentation.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import UIKit

enum AnalyticsBottomSheetMetrics {
    static let cornerRadius: CGFloat = 32
    static let grabberWidth: CGFloat = 36
    static let grabberHeight: CGFloat = 5
    static let grabberTopInset: CGFloat = 8
    static let dimmingAlpha: CGFloat = 0.45
    static let transitionDuration: TimeInterval = 0.3
    static let dismissalProgressThreshold: CGFloat = 0.22
    static let dismissalVelocityThreshold: CGFloat = 900
    static let maximumTopInset: CGFloat = 8
    static let scrollTopTolerance: CGFloat = 0.5
}

final class AnalyticsBottomSheetPresentationController:
    UIPresentationController,
    UIGestureRecognizerDelegate {
    // MARK: - Properties

    private let dimmingView = UIView()
    private let grabberView = UIView()
    private var isDismissing = false

    // MARK: - Presentation

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView else {
            return .zero
        }

        let containerBounds = containerView.bounds
        let maximumHeight = max(
            containerBounds.height
                - containerView.safeAreaInsets.top
                - AnalyticsBottomSheetMetrics.maximumTopInset,
            .zero
        )
        let contentHeight = (
            presentedViewController as? AnalyticsSheetHeightProviding
        )?.resolvedSheetHeight(
            containerWidth: containerBounds.width,
            bottomSafeAreaInset: containerView.safeAreaInsets.bottom,
            maximumHeight: maximumHeight
        ) ?? maximumHeight

        return CGRect(
            x: containerBounds.minX,
            y: containerBounds.maxY - contentHeight,
            width: containerBounds.width,
            height: contentHeight
        )
    }

    override func presentationTransitionWillBegin() {
        guard let containerView else {
            return
        }

        configureDimmingView(in: containerView)
        configurePresentedView()
        dimmingView.alpha = .zero

        presentedViewController.transitionCoordinator?.animate {
            [weak self] _ in
            self?.dimmingView.alpha = AnalyticsBottomSheetMetrics.dimmingAlpha
        }
        if presentedViewController.transitionCoordinator == nil {
            dimmingView.alpha = AnalyticsBottomSheetMetrics.dimmingAlpha
        }
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        if !completed {
            dimmingView.removeFromSuperview()
        }
    }

    override func dismissalTransitionWillBegin() {
        isDismissing = true
        guard let transitionCoordinator =
            presentedViewController.transitionCoordinator
        else {
            dimmingView.alpha = .zero
            return
        }

        transitionCoordinator.animate {
            [weak self] _ in
            self?.dimmingView.alpha = .zero
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            dimmingView.removeFromSuperview()
        } else {
            isDismissing = false
            presentedView?.transform = .identity
            dimmingView.alpha = AnalyticsBottomSheetMetrics.dimmingAlpha
        }
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        dimmingView.frame = containerView?.bounds ?? .zero
        guard let presentedView else {
            return
        }

        let targetFrame = frameOfPresentedViewInContainerView
        presentedView.bounds = CGRect(
            origin: .zero,
            size: targetFrame.size
        )
        presentedView.center = CGPoint(
            x: targetFrame.midX,
            y: targetFrame.midY
        )
    }

    // MARK: - Private Methods

    private func configureDimmingView(in containerView: UIView) {
        dimmingView.frame = containerView.bounds
        dimmingView.backgroundColor = .black
        dimmingView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(dismissPresentedViewController)
            )
        )
        containerView.insertSubview(dimmingView, at: 0)
    }

    private func configurePresentedView() {
        guard let presentedView else {
            return
        }

        presentedView.layer.cornerRadius =
            AnalyticsBottomSheetMetrics.cornerRadius
        presentedView.layer.cornerCurve = .continuous
        presentedView.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner
        ]
        presentedView.clipsToBounds = true

        grabberView.translatesAutoresizingMaskIntoConstraints = false
        grabberView.backgroundColor = .tertiaryLabel
        grabberView.layer.cornerRadius =
            AnalyticsBottomSheetMetrics.grabberHeight / 2
        grabberView.isUserInteractionEnabled = false
        presentedView.addSubview(grabberView)

        NSLayoutConstraint.activate([
            grabberView.topAnchor.constraint(
                equalTo: presentedView.topAnchor,
                constant: AnalyticsBottomSheetMetrics.grabberTopInset
            ),
            grabberView.centerXAnchor.constraint(
                equalTo: presentedView.centerXAnchor
            ),
            grabberView.widthAnchor.constraint(
                equalToConstant: AnalyticsBottomSheetMetrics.grabberWidth
            ),
            grabberView.heightAnchor.constraint(
                equalToConstant: AnalyticsBottomSheetMetrics.grabberHeight
            )
        ])

        let panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePanGesture(_:))
        )
        panGesture.delegate = self
        presentedView.addGestureRecognizer(panGesture)
    }

    @objc private func dismissPresentedViewController() {
        guard !isDismissing else {
            return
        }

        isDismissing = true
        presentedViewController.dismiss(animated: true)
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let presentedView else {
            return
        }

        let translation = max(
            gesture.translation(in: presentedView).y,
            .zero
        )
        let progress = min(
            translation / max(presentedView.bounds.height, 1),
            1
        )

        switch gesture.state {
        case .changed:
            presentedView.transform = CGAffineTransform(
                translationX: .zero,
                y: translation
            )
            dimmingView.alpha = AnalyticsBottomSheetMetrics.dimmingAlpha
                * (1 - progress)
        case .ended:
            let velocity = gesture.velocity(in: presentedView).y
            if progress
                >= AnalyticsBottomSheetMetrics.dismissalProgressThreshold
                || velocity
                    >= AnalyticsBottomSheetMetrics.dismissalVelocityThreshold {
                dismissPresentedViewController()
            } else {
                restoreAfterPan(presentedView)
            }
        case .cancelled, .failed:
            restoreAfterPan(presentedView)
        default:
            break
        }
    }

    private func restoreAfterPan(_ presentedView: UIView) {
        UIView.animate(
            withDuration: AnalyticsBottomSheetMetrics.transitionDuration,
            delay: .zero,
            options: [
                .curveEaseOut,
                .beginFromCurrentState,
                .allowUserInteraction
            ]
        ) { [weak self] in
            presentedView.transform = .identity
            self?.dimmingView.alpha =
                AnalyticsBottomSheetMetrics.dimmingAlpha
        }
    }

    func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard !isDismissing else {
            return false
        }

        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }

        let velocity = panGesture.velocity(in: presentedView)
        guard velocity.y > .zero, abs(velocity.y) > abs(velocity.x) else {
            return false
        }

        guard let scrollView = scrollView(at: panGesture) else {
            return true
        }

        let topOffset = -scrollView.adjustedContentInset.top
        return scrollView.contentOffset.y
            <= topOffset + AnalyticsBottomSheetMetrics.scrollTopTolerance
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer:
            UIGestureRecognizer
    ) -> Bool {
        guard
            gestureRecognizer is UIPanGestureRecognizer,
            let presentedView,
            let scrollView = otherGestureRecognizer.view as? UIScrollView
        else {
            return false
        }

        return scrollView.isDescendant(of: presentedView)
    }

    private func scrollView(
        at gestureRecognizer: UIGestureRecognizer
    ) -> UIScrollView? {
        guard let presentedView else {
            return nil
        }

        let location = gestureRecognizer.location(in: presentedView)
        var candidate = presentedView.hitTest(location, with: nil)

        while let view = candidate {
            if let scrollView = view as? UIScrollView,
               scrollView.isScrollEnabled,
               scrollView.contentSize.height > scrollView.bounds.height {
                return scrollView
            }
            candidate = view.superview
        }

        return nil
    }
}
