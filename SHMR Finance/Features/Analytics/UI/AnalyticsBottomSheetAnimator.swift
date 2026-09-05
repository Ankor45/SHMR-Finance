//
//  AnalyticsBottomSheetAnimator.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import UIKit

final class AnalyticsBottomSheetAnimator: NSObject,
    UIViewControllerAnimatedTransitioning {
    private let isPresenting: Bool

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }

    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        AnalyticsBottomSheetMetrics.transitionDuration
    }

    func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        isPresenting
            ? animatePresentation(using: transitionContext)
            : animateDismissal(using: transitionContext)
    }

    private func animatePresentation(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        guard
            let presentedViewController = transitionContext.viewController(
                forKey: .to
            ),
            let presentedView = transitionContext.view(forKey: .to)
        else {
            transitionContext.completeTransition(false)
            return
        }

        transitionContext.containerView.addSubview(presentedView)
        presentedView.frame = transitionContext.finalFrame(
            for: presentedViewController
        )
        presentedView.transform = CGAffineTransform(
            translationX: .zero,
            y: presentedView.bounds.height
        )

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: .zero,
            options: [.curveEaseOut]
        ) {
            presentedView.transform = .identity
        } completion: { _ in
            transitionContext.completeTransition(
                !transitionContext.transitionWasCancelled
            )
        }
    }

    private func animateDismissal(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        guard let presentedView = transitionContext.view(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: .zero,
            options: [.curveEaseIn]
        ) {
            presentedView.transform = CGAffineTransform(
                translationX: .zero,
                y: presentedView.bounds.height
            )
        } completion: { _ in
            let completed = !transitionContext.transitionWasCancelled
            if !completed {
                presentedView.transform = .identity
            }
            transitionContext.completeTransition(completed)
        }
    }
}
