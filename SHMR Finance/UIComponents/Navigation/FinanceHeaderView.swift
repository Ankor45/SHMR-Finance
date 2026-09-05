//
//  FinanceHeaderView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import SwiftUI
import UIKit

private enum Constants {
    enum Analytics {
        static var title: String { AppLocalization.string(localized: "Аналитика") }
        static let icon = "chart.pie"
    }

    enum Settings {
        static var title: String { AppLocalization.string(localized: "Настройки") }
        static let icon = "slider.horizontal.3"
    }

    enum Border {
        static let opacity = 0.18
        static let width: CGFloat = 0.5
    }

    static let horizontalPadding: CGFloat = 20
    static let verticalPadding: CGFloat = 4
    static let iPadTopSafeAreaPadding: CGFloat = 36
    static let contentSpacing: CGFloat = 12
    static let actionWidth: CGFloat = 44
    static let actionHeight: CGFloat = 44
    static let actionFont = Font.body.weight(.medium)
}

struct FinanceHeaderView<Leading: View>: View {
    // MARK: - Properties

    private let leading: Leading
    private let analyticsAction: () -> Void
    private let settingsAction: () -> Void
    // MARK: - Initializers

    init(
        @ViewBuilder leading: () -> Leading,
        analyticsAction: @escaping () -> Void,
        settingsAction: @escaping () -> Void
    ) {
        self.leading = leading()
        self.analyticsAction = analyticsAction
        self.settingsAction = settingsAction
    }
    // MARK: - View Body

    var body: some View {
        HStack {
            leading

            Spacer(minLength: Constants.contentSpacing)

            headerActions
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
        .safeAreaPadding(
            .top,
            UIDevice.current.userInterfaceIdiom == .pad
                ? Constants.iPadTopSafeAreaPadding
                : .zero
        )
        .adaptiveContentWidth()
    }
    // MARK: - Private Properties

    @ViewBuilder
    private var headerActions: some View {
        if #available(iOS 26.0, *) {
            actions
                .glassEffect(.regular, in: Capsule())
        } else {
            actions
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(
                            Color.white.opacity(Constants.Border.opacity),
                            lineWidth: Constants.Border.width
                        )
                }
                .clipShape(Capsule())
        }
    }

    private var actions: some View {
        HStack(spacing: .zero) {
            analyticsControl

            settingsControl
        }
        .font(Constants.actionFont)
        .foregroundStyle(Color.primary)
        .buttonStyle(.plain)
    }

    private var analyticsControl: some View {
        Button(action: analyticsAction) {
            analyticsLabel
        }
        .accessibilityLabel(Constants.Analytics.title)
    }

    private var analyticsLabel: some View {
        Image(systemName: Constants.Analytics.icon)
            .frame(
                width: Constants.actionWidth,
                height: Constants.actionHeight
            )
            .contentShape(Rectangle())
    }

    private var settingsControl: some View {
        Button(action: settingsAction) {
            settingsLabel
        }
        .accessibilityLabel(Constants.Settings.title)
    }

    private var settingsLabel: some View {
        Image(systemName: Constants.Settings.icon)
            .frame(
                width: Constants.actionWidth,
                height: Constants.actionHeight
            )
            .contentShape(Rectangle())
    }
}
