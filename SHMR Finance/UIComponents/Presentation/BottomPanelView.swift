//
//  BottomPanelView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import SwiftUI

private enum Constants {
    static let cornerRadius: CGFloat = 28
    static let dragIndicatorWidth: CGFloat = 36
    static let dragIndicatorHeight: CGFloat = 5
    static let dragIndicatorTopPadding: CGFloat = 6
    static let dismissTranslation: CGFloat = 60
    static let minimumDragDistance: CGFloat = 20
    static let dragAreaWidth: CGFloat = 88
    static let dragAreaHeight: CGFloat = 44
    static let backgroundColor = Color(.systemBackground)
    static let dragIndicatorColor =
        Color.secondary.opacity(0.35)
}

struct BottomPanelView<Content: View>: View {
    let height: CGFloat
    let verticalOffset: CGFloat
    let isDismissEnabled: Bool
    let onDismiss: () -> Void

    private let content: Content

    init(
        height: CGFloat,
        verticalOffset: CGFloat = .zero,
        isDismissEnabled: Bool = true,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.height = height
        self.verticalOffset = verticalOffset
        self.isDismissEnabled = isDismissEnabled
        self.onDismiss = onDismiss
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .contentShape(Rectangle())
            .background(Constants.backgroundColor)
            .clipShape(
                .rect(
                    topLeadingRadius: Constants.cornerRadius,
                    topTrailingRadius: Constants.cornerRadius
                )
            )
            .overlay(alignment: .top) {
                dragArea
            }
            .offset(y: verticalOffset)
    }

    private var dragArea: some View {
        Color.clear
            .frame(
                width: Constants.dragAreaWidth,
                height: Constants.dragAreaHeight
            )
            .contentShape(Rectangle())
            .overlay(alignment: .top) {
                Capsule()
                    .fill(Constants.dragIndicatorColor)
                    .frame(
                        width: Constants.dragIndicatorWidth,
                        height: Constants.dragIndicatorHeight
                    )
                    .padding(
                        .top,
                        Constants.dragIndicatorTopPadding
                    )
            }
            .gesture(dismissGesture)
    }

    private var dismissGesture: some Gesture {
        DragGesture(
            minimumDistance: Constants.minimumDragDistance
        )
        .onEnded { value in
            let verticalTranslation = value.translation.height
            let horizontalTranslation =
                abs(value.translation.width)

            guard
                isDismissEnabled,
                verticalTranslation > Constants.dismissTranslation,
                verticalTranslation > horizontalTranslation
            else {
                return
            }

            onDismiss()
        }
    }
}
