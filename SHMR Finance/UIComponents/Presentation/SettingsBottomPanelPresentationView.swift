//
//  SettingsBottomPanelPresentationView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 05.08.2026.
//

import SwiftUI
import UIKit

private enum Constants {
    static let accessibilityHeightScale = 1.3
    static let accessibilityFractionIncrement = 0.15
}

struct SettingsBottomPanelPresentationView<Content: View>: View {
    // MARK: - Properties

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let preferredHeightFraction: CGFloat
    private let minimumHeight: CGFloat
    private let maximumHeight: CGFloat
    private let onDismiss: () -> Void
    private let content: Content

    // MARK: - Initializers

    init(
        preferredHeightFraction: CGFloat,
        minimumHeight: CGFloat,
        maximumHeight: CGFloat,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.preferredHeightFraction = preferredHeightFraction
        self.minimumHeight = minimumHeight
        self.maximumHeight = maximumHeight
        self.onDismiss = onDismiss
        self.content = content()
    }

    // MARK: - View Body

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                backdrop

                BottomPanelView(
                    height: panelHeight(for: proxy.size.height),
                    onDismiss: onDismiss
                ) {
                    content
                }
            }
        }
        .ignoresSafeArea()
        .presentationBackground(.clear)
    }

    // MARK: - Private Properties

    private var backdrop: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(perform: onDismiss)
    }

    // MARK: - Private Methods

    private func panelHeight(for availableHeight: CGFloat) -> CGFloat {
        guard UIDevice.current.userInterfaceIdiom != .pad else {
            return availableHeight
        }

        let preferredHeight =
            availableHeight * resolvedPreferredHeightFraction
        let resolvedMinimumHeight = min(
            minimumHeight,
            availableHeight
        )
        let resolvedMaximumHeight = min(
            accessibilityAdjustedMaximumHeight,
            availableHeight
        )

        return min(
            max(preferredHeight, resolvedMinimumHeight),
            resolvedMaximumHeight
        )
    }

    private var resolvedPreferredHeightFraction: CGFloat {
        guard dynamicTypeSize.isAccessibilitySize else {
            return preferredHeightFraction
        }

        return min(
            preferredHeightFraction
                + Constants.accessibilityFractionIncrement,
            1
        )
    }

    private var accessibilityAdjustedMaximumHeight: CGFloat {
        guard dynamicTypeSize.isAccessibilitySize else {
            return maximumHeight
        }

        return maximumHeight * Constants.accessibilityHeightScale
    }
}
