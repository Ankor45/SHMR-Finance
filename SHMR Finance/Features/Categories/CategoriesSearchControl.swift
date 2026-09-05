//
//  CategoriesSearchControl.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 01.08.2026.
//

import SwiftUI

struct CategoriesSearchControl: View {
    private enum Constants {
        static var prompt: String { AppLocalization.string(localized: "Поиск") }
        static var openTitle: String {
            AppLocalization.string(
                localized: "Открыть поиск"
            )
        }
        static var cancelTitle: String { AppLocalization.string(localized: "Отмена") }
        static var clearTitle: String {
            AppLocalization.string(
                localized: "Очистить поиск"
            )
        }
        static let searchIcon = "magnifyingglass"
        static let clearIcon = "xmark.circle.fill"
        static let cancelIcon = "xmark"
        static let buttonSize: CGFloat = 44
        static let controlHeight: CGFloat = 44
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 8
        static let fieldHorizontalPadding: CGFloat = 12
        static let fieldSpacing: CGFloat = 8
        static let shadowOpacity = 0.12
        static let shadowRadius: CGFloat = 10
        static let shadowY: CGFloat = 4
    }

    @Binding private var searchText: String
    private let isPresented: Bool
    private let onPresent: () -> Void
    private let onCancel: () -> Void

    @FocusState private var isFocused: Bool

    init(
        searchText: Binding<String>,
        isPresented: Bool,
        onPresent: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        _searchText = searchText
        self.isPresented = isPresented
        self.onPresent = onPresent
        self.onCancel = onCancel
    }

    var body: some View {
        Group {
            if isPresented {
                activeSearchControl
            } else {
                searchButton
            }
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
        .background {
            if #available(iOS 26.0, *) {
                Color.clear
            } else {
                Color(.systemBackground)
            }
        }
    }

    private var searchButton: some View {
        HStack {
            Spacer()

            if #available(iOS 26.0, *) {
                searchButtonLabel
                    .glassEffect(.regular.interactive(), in: Circle())
            } else {
                searchButtonLabel
                    .background(
                        Color(.secondarySystemBackground),
                        in: Circle()
                    )
                    .shadow(
                        color: .black.opacity(Constants.shadowOpacity),
                        radius: Constants.shadowRadius,
                        y: Constants.shadowY
                    )
            }
        }
    }

    private var searchButtonLabel: some View {
        Button(
            Constants.openTitle,
            systemImage: Constants.searchIcon,
            action: presentSearch
        )
        .labelStyle(.iconOnly)
        .foregroundStyle(.primary)
        .frame(
            width: Constants.buttonSize,
            height: Constants.buttonSize
        )
        .contentShape(Circle())
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var activeSearchControl: some View {
        HStack(spacing: Constants.fieldSpacing) {
            if #available(iOS 26.0, *) {
                searchField
                    .glassEffect(.regular.interactive(), in: Capsule())

                cancelButton
                    .glassEffect(.regular.interactive(), in: Circle())
            } else {
                searchField
                    .background(
                        Color(.secondarySystemBackground),
                        in: Capsule()
                    )
                    .shadow(
                        color: .black.opacity(Constants.shadowOpacity),
                        radius: Constants.shadowRadius,
                        y: Constants.shadowY
                    )

                cancelButton
                    .background(
                        Color(.secondarySystemBackground),
                        in: Circle()
                    )
                    .shadow(
                        color: .black.opacity(Constants.shadowOpacity),
                        radius: Constants.shadowRadius,
                        y: Constants.shadowY
                    )
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: Constants.fieldSpacing) {
            Image(systemName: Constants.searchIcon)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(Constants.prompt, text: $searchText)
                .focused($isFocused)
                .submitLabel(.search)

            if !searchText.isEmpty {
                Button(
                    Constants.clearTitle,
                    systemImage: Constants.clearIcon,
                    action: clearSearch
                )
                .labelStyle(.iconOnly)
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Constants.fieldHorizontalPadding)
        .frame(minHeight: Constants.controlHeight)
        .onAppear {
            isFocused = true
        }
    }

    private var cancelButton: some View {
        Button(
            Constants.cancelTitle,
            systemImage: Constants.cancelIcon,
            action: dismissSearch
        )
        .labelStyle(.iconOnly)
        .frame(
            width: Constants.buttonSize,
            height: Constants.buttonSize
        )
        .contentShape(Circle())
        .buttonStyle(.plain)
    }

    private func presentSearch() {
        onPresent()
    }

    private func dismissSearch() {
        onCancel()
    }

    private func clearSearch() {
        searchText.removeAll()
    }
}
