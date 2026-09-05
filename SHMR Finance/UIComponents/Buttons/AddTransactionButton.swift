//
//  AddTransactionButton.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 18.07.2026.
//

import SwiftUI

private enum Constants {
    enum Border {
        static let opacity = 0.18
        static let width: CGFloat = 0.5
    }

    static let icon = "plus"
    static var defaultAccessibilityLabel: String {
        AppLocalization.string(
            localized: "Добавить операцию"
        )
    }
    static let iconFont = Font.title2.weight(.medium)
    static let iconColor = Color.white
    static let shadowOpacity = 0.16
    static let shadowRadius: CGFloat = 16
    static let shadowYOffset: CGFloat = 8
}

enum AddTransactionButtonMetrics {
    static let size: CGFloat = 64
    static let trailingPadding: CGFloat = 20
    static let tabBarSpacing: CGFloat = 15

    static var bottomPadding: CGFloat {
        AppTabBarMetrics.scrollClearance + tabBarSpacing
    }

    static var scrollClearance: CGFloat {
        bottomPadding + size
    }
}

struct AddTransactionButton: View {
    // MARK: - Properties

    let accessibilityLabel: String
    let tintColor: Color
    let action: () -> Void

    // MARK: - Initializers

    init(
        accessibilityLabel: String = Constants.defaultAccessibilityLabel,
        tintColor: Color,
        action: @escaping () -> Void
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.tintColor = tintColor
        self.action = action
    }

    // MARK: - View Body

    var body: some View {
        if #available(iOS 26.0, *) {
            button
                .glassEffect(
                    .regular
                        .tint(tintColor)
                        .interactive(),
                    in: Circle()
                )
        } else {
            button
                .background(tintColor, in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(
                            Color.white.opacity(Constants.Border.opacity),
                            lineWidth: Constants.Border.width
                        )
                }
                .clipShape(Circle())
                .shadow(
                    color: .black.opacity(Constants.shadowOpacity),
                    radius: Constants.shadowRadius,
                    y: Constants.shadowYOffset
                )
        }
    }

    // MARK: - Private Properties

    private var button: some View {
        Button(action: action) {
            Image(systemName: Constants.icon)
                .font(Constants.iconFont)
                .foregroundStyle(Constants.iconColor)
                .frame(
                    width: AddTransactionButtonMetrics.size,
                    height: AddTransactionButtonMetrics.size
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
