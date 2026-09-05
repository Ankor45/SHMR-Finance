//
//  CategoriesListView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import SwiftUI

private enum Constants {
    enum Navigation {
        static var title: String { AppLocalization.string(localized: "Статьи") }
        static let closeIcon = "xmark"
        static var closeAccessibilityLabel: String {
            AppLocalization.string(
                localized: "Закрыть"
            )
        }
    }

    enum Loading {
        static var title: String {
            AppLocalization.string(
                localized: "Загрузка статей…"
            )
        }
    }

    enum ErrorState {
        static var title: String {
            AppLocalization.string(
                localized: "Не удалось загрузить статьи"
            )
        }
        static let icon = "exclamationmark.triangle"
        static var retryTitle: String { AppLocalization.string(localized: "Повторить") }
    }

    enum EmptyState {
        static var title: String { AppLocalization.string(localized: "Статей нет") }
        static let icon = "tray"
        static var description: String {
            AppLocalization.string(
                localized: "Для этого направления статьи не найдены"
            )
        }
    }

    enum SearchEmptyState {
        static var title: String {
            AppLocalization.string(
                localized: "Ничего не найдено"
            )
        }
        static let icon = "magnifyingglass"
        static var description: String {
            AppLocalization.string(
                localized: "Попробуйте изменить поисковый запрос"
            )
        }
    }

    enum List {
        static let rowHorizontalInset: CGFloat = 16

        static let rowInsets = EdgeInsets(
            top: .zero,
            leading: rowHorizontalInset,
            bottom: .zero,
            trailing: rowHorizontalInset
        )
    }

    enum Sheet {
        static let compactDetent = PresentationDetent.fraction(0.64)
        static let cornerRadius: CGFloat = 28
    }

    static let backgroundColor = Color(.systemBackground)
}

struct CategoriesListView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss

    private let onSelect: ((Category) -> Void)?

    // MARK: - State

    @State private var viewModel: CategoriesListViewModel
    @State private var selectedDetent = Constants.Sheet.compactDetent
    @State private var isSearchPresented = false

    // MARK: - Initializers

    init(
        direction: Direction,
        service: any CategoryServiceProviding,
        onSelect: ((Category) -> Void)? = nil
    ) {
        self.onSelect = onSelect
        _viewModel = State(
            initialValue: CategoriesListViewModel(
                direction: direction,
                service: service
            )
        )
    }

    // MARK: - View Body

    var body: some View {
        @Bindable var viewModel = viewModel

        navigationContent(
            searchText: $viewModel.searchText
        )
        .presentationDetents(
            [Constants.Sheet.compactDetent, .large],
            selection: $selectedDetent
        )
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.resizes)
        .presentationCornerRadius(Constants.Sheet.cornerRadius)
        .onChange(of: selectedDetent) { _, detent in
            if isSearchPresented,
               detent == Constants.Sheet.compactDetent {
                dismiss()
            }
        }
        .task {
            await viewModel.loadCategoriesIfNeeded()
        }
    }

    // MARK: - Private Properties

    private func navigationContent(
        searchText: Binding<String>
    ) -> some View {
        NavigationStack {
            navigationRoot
                .safeAreaInset(edge: .bottom, spacing: .zero) {
                    CategoriesSearchControl(
                        searchText: searchText,
                        isPresented: isSearchPresented,
                        onPresent: presentSearch,
                        onCancel: {
                            dismiss()
                        }
                    )
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        closeButton
                    }
                }
        }
    }

    private var navigationRoot: some View {
        content
            .background(Constants.backgroundColor)
            .navigationTitle(Constants.Navigation.title)
            .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView(Constants.Loading.title)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage {
            ContentUnavailableView {
                Label(
                    Constants.ErrorState.title,
                    systemImage: Constants.ErrorState.icon
                )
            } description: {
                Text(errorMessage)
            } actions: {
                Button(Constants.ErrorState.retryTitle) {
                    Task {
                        await viewModel.retry()
                    }
                }
            }
        } else if viewModel.categories.isEmpty {
            ContentUnavailableView(
                Constants.EmptyState.title,
                systemImage: Constants.EmptyState.icon,
                description: Text(Constants.EmptyState.description)
            )
        } else if viewModel.filteredCategories.isEmpty {
            ContentUnavailableView(
                Constants.SearchEmptyState.title,
                systemImage: Constants.SearchEmptyState.icon,
                description: Text(
                    Constants.SearchEmptyState.description
                )
            )
        } else {
            categoriesList
        }
    }

    private var categoriesList: some View {
        List(viewModel.filteredCategories) { category in
            categoryRow(for: category)
                .listRowInsets(Constants.List.rowInsets)
                .listRowSeparatorTint(Color(.separator))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var closeButton: some View {
        Button(role: .cancel) {
            dismiss()
        } label: {
            Image(systemName: Constants.Navigation.closeIcon)
                .foregroundStyle(.primary)
        }
        .accessibilityLabel(
            Constants.Navigation.closeAccessibilityLabel
        )
    }

    private func presentSearch() {
        selectedDetent = .large
        isSearchPresented = true
    }

    @ViewBuilder
    private func categoryRow(for category: Category) -> some View {
        if let onSelect {
            Button {
                onSelect(category)
                dismiss()
            } label: {
                CategoryRowView(category: category)
            }
            .buttonStyle(.plain)
        } else {
            CategoryRowView(category: category)
        }
    }
}
