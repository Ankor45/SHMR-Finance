//
//  AnalyticsBottomSheetTransitioningDelegate.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import UIKit

final class AnalyticsBottomSheetTransitioningDelegate: NSObject,
    UIViewControllerTransitioningDelegate {
    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        AnalyticsBottomSheetPresentationController(
            presentedViewController: presented,
            presenting: presenting
        )
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        AnalyticsBottomSheetAnimator(isPresenting: true)
    }

    func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        AnalyticsBottomSheetAnimator(isPresenting: false)
    }
}
