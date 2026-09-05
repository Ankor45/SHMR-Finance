//
//  TransactionEditorInputDismissalOverlay.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import SwiftUI

struct TransactionEditorInputDismissalOverlay: View {
    // MARK: - Properties

    let excludedFrame: CGRect
    let onDismiss: () -> Void

    // MARK: - View Body

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: .zero) {
                dismissalArea
                    .frame(
                        height: max(
                            .zero,
                            excludedFrame.minY
                        )
                    )

                Color.clear
                    .frame(
                        height: max(
                            .zero,
                            excludedFrame.height
                        )
                    )
                    .allowsHitTesting(false)

                dismissalArea
                    .frame(maxHeight: .infinity)
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height
            )
        }
    }

    // MARK: - Private Properties

    private var dismissalArea: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(perform: onDismiss)
    }
}
