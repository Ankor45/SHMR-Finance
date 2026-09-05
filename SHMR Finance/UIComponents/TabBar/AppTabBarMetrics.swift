//
//  AppTabBarMetrics.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 18.07.2026.
//

import CoreGraphics

enum AppTabBarMetrics {
    static let height: CGFloat = 62
    static let maximumWidth: CGFloat = 302
    static let verticalPadding: CGFloat = 8

    static var scrollClearance: CGFloat {
        height + verticalPadding * 2
    }
}
