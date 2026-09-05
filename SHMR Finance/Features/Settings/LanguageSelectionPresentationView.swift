//
//  LanguageSelectionPresentationView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 06.08.2026.
//

import SwiftUI

private enum Constants {
    static let preferredHeightFraction = 0.28
    static let minimumHeight: CGFloat = 250
    static let maximumHeight: CGFloat = 270
    static let horizontalPadding: CGFloat = 21
    static let topPadding: CGFloat = 38
    static let contentSpacing: CGFloat = 22
    static let rowHeight: CGFloat = 58
    static let selectedIcon = "checkmark"
    static let selectedIconFont = Font.body.weight(.semibold)
}

struct LanguageSelectionPresentationView: View {
    @Binding var selection: AppLanguage

    let onDismiss: () -> Void

    var body: some View {
        SettingsBottomPanelPresentationView(
            preferredHeightFraction: Constants.preferredHeightFraction,
            minimumHeight: Constants.minimumHeight,
            maximumHeight: Constants.maximumHeight,
            onDismiss: onDismiss
        ) {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Constants.contentSpacing) {
            Text(
                AppLocalization.string(localized: "Языки")
            )
                .font(.title2.bold())

            VStack(spacing: .zero) {
                ForEach(
                    Array(AppLanguage.allCases.enumerated()),
                    id: \.element
                ) { index, language in
                    languageButton(for: language)

                    if index < AppLanguage.allCases.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.top, Constants.topPadding)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func languageButton(for language: AppLanguage) -> some View {
        Button {
            selection = language
        } label: {
            HStack {
                Text(language.displayTitle)

                Spacer()

                if selection == language {
                    Image(systemName: Constants.selectedIcon)
                        .font(Constants.selectedIconFont)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .foregroundStyle(Color.primary)
            .frame(height: Constants.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            selection == language ? .isSelected : []
        )
    }
}
