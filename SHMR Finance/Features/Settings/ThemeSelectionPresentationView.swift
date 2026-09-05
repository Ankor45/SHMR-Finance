//
//  ThemeSelectionPresentationView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 05.08.2026.
//

import SwiftUI

private enum Constants {
    static let preferredHeightFraction = 0.28
    static let minimumHeight: CGFloat = 250
    static let maximumHeight: CGFloat = 270
    static let horizontalPadding: CGFloat = 21
    static let topPadding: CGFloat = 38
    static let contentSpacing: CGFloat = 28
    static let cardSpacing: CGFloat = 14
    static let cardHeight: CGFloat = 110
    static let cardMaximumWidth: CGFloat = 114
    static let cardCornerRadius: CGFloat = 15
    static let cardBorderWidth: CGFloat = 2
    static let cardContentPadding: CGFloat = 11
    static let previewHeight: CGFloat = 59
    static let previewCornerRadius: CGFloat = 8
    static let previewBorderWidth: CGFloat = 1
    static let optionSpacing: CGFloat = 8
    static let optionFont = Font.footnote
    static let unselectedBorderColor = Color(.systemGray4)
    static let previewBorderColor = Color(.systemGray5)
    static let darkPreviewColor = Color(
        red: 28 / 255,
        green: 27 / 255,
        blue: 31 / 255
    )
}

struct ThemeSelectionPresentationView: View {
    // MARK: - Properties

    @Binding var selection: AppTheme

    let title: String
    let onDismiss: () -> Void

    // MARK: - View Body

    var body: some View {
        SettingsBottomPanelPresentationView(
            preferredHeightFraction:
                Constants.preferredHeightFraction,
            minimumHeight: Constants.minimumHeight,
            maximumHeight: Constants.maximumHeight,
            onDismiss: onDismiss
        ) {
            content
        }
    }

    // MARK: - Private Properties

    private var content: some View {
        VStack(alignment: .leading, spacing: Constants.contentSpacing) {
            Text(title)
                .font(.title2.bold())

            HStack(spacing: Constants.cardSpacing) {
                ForEach(AppTheme.allCases) { theme in
                    themeButton(for: theme)
                }
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.top, Constants.topPadding)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Private Methods

    private func themeButton(for theme: AppTheme) -> some View {
        Button {
            selection = theme
        } label: {
            VStack(spacing: Constants.optionSpacing) {
                themePreview(for: theme)
                    .frame(height: Constants.previewHeight)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: Constants.previewCornerRadius
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: Constants.previewCornerRadius
                        )
                        .stroke(
                            Constants.previewBorderColor,
                            lineWidth: Constants.previewBorderWidth
                        )
                    }

                Label(
                    theme.title,
                    systemImage: iconName(for: theme)
                )
                .font(Constants.optionFont)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            .foregroundStyle(Color.primary)
            .padding(Constants.cardContentPadding)
            .frame(maxWidth: .infinity)
            .frame(height: Constants.cardHeight)
            .contentShape(
                RoundedRectangle(
                    cornerRadius: Constants.cardCornerRadius
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: Constants.cardCornerRadius
                )
                .stroke(
                    selection == theme
                        ? Color.accentColor
                        : Constants.unselectedBorderColor,
                    lineWidth: Constants.cardBorderWidth
                )
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: Constants.cardMaximumWidth)
        .accessibilityAddTraits(
            selection == theme ? .isSelected : []
        )
    }

    @ViewBuilder
    private func themePreview(for theme: AppTheme) -> some View {
        switch theme {
        case .light:
            Color.white

        case .dark:
            Constants.darkPreviewColor

        case .system:
            LinearGradient(
                colors: [
                    Color.white,
                    Constants.darkPreviewColor
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private func iconName(for theme: AppTheme) -> String {
        switch theme {
        case .light:
            "sun.max"
        case .dark:
            "moon"
        case .system:
            "iphone"
        }
    }
}
