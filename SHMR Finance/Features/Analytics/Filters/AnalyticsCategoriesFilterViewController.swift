//
//  AnalyticsCategoriesFilterViewController.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import UIKit

private enum Constants {
    static var title: String { AppLocalization.string(localized: "Статьи") }
    static var allCategoriesTitle: String { AppLocalization.string(localized: "Все") }
    static var loadingTitle: String {
        AppLocalization.string(
            localized: "Загрузка статей…"
        )
    }
    static var emptyTitle: String { AppLocalization.string(localized: "Статей нет") }
    static var retryTitle: String { AppLocalization.string(localized: "Повторить") }
    static let statusSpacing: CGFloat = 12
    static let statusNumberOfLines = 0
    static let statusHorizontalInset: CGFloat = 24
}

final class AnalyticsCategoriesFilterViewController: UIViewController {
    // MARK: - Properties

    private let viewModel: AnalyticsCategoriesFilterViewModel
    private let onSelection: (Set<Int>?, [Category]) -> Void
    private let tableView = AnalyticsFilterTableView()
    private lazy var headerView = AnalyticsFilterHeaderView(
        title: Constants.title,
        showsConfirmation: true,
        onClose: { [weak self] in
            self?.dismiss(animated: true)
        },
        onConfirm: { [weak self] in
            self?.applySelection()
        }
    )
    private var loadTask: Task<Void, Never>?

    // MARK: - Initializers

    init(
        selectedCategoryIDs: Set<Int>?,
        loadCategories: @escaping () async throws -> [Category],
        onSelection: @escaping (Set<Int>?, [Category]) -> Void
    ) {
        viewModel = AnalyticsCategoriesFilterViewModel(
            selectedCategoryIDs: selectedCategoryIDs,
            loadCategories: loadCategories
        )
        self.onSelection = onSelection
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        viewModel.onStateChange = { [weak self] in
            self?.render()
        }
        loadCategories()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard isBeingDismissed else {
            return
        }

        loadTask?.cancel()
        viewModel.cancelLoading()
        viewModel.onStateChange = nil
    }

    // MARK: - Private Methods

    private func configureView() {
        view.backgroundColor = .systemBackground

        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(headerView)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(
                equalToConstant: AnalyticsFilterSheetMetrics.headerHeight
            ),
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor
            )
        ])
    }

    private func render() {
        headerView.isConfirmationEnabled = viewModel.state == .loaded
        tableView.reloadData()
        tableView.backgroundView = makeStatusView()
    }

    private func makeStatusView() -> UIView? {
        switch viewModel.state {
        case .loading:
            return makeLoadingView()
        case .loaded where viewModel.categories.isEmpty:
            return makeMessageView(title: Constants.emptyTitle)
        case .loaded:
            return nil
        case .failed(let message):
            return makeMessageView(title: message, showsRetry: true)
        }
    }

    private func makeLoadingView() -> UIView {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        return makeStatusStack(
            arrangedSubviews: [
                indicator,
                makeStatusLabel(text: Constants.loadingTitle)
            ]
        )
    }

    private func makeMessageView(
        title: String,
        showsRetry: Bool = false
    ) -> UIView {
        var arrangedSubviews: [UIView] = [makeStatusLabel(text: title)]
        if showsRetry {
            arrangedSubviews.append(makeRetryButton())
        }
        return makeStatusStack(arrangedSubviews: arrangedSubviews)
    }

    private func makeStatusStack(
        arrangedSubviews: [UIView]
    ) -> UIView {
        let containerView = UIView()
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Constants.statusSpacing
        containerView.addSubview(stackView)

        let leadingConstraint = stackView.leadingAnchor.constraint(
            greaterThanOrEqualTo: containerView.leadingAnchor,
            constant: Constants.statusHorizontalInset
        )
        leadingConstraint.priority = .defaultHigh
        let trailingConstraint = stackView.trailingAnchor.constraint(
            lessThanOrEqualTo: containerView.trailingAnchor,
            constant: -Constants.statusHorizontalInset
        )
        trailingConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(
                equalTo: containerView.centerXAnchor
            ),
            stackView.centerYAnchor.constraint(
                equalTo: containerView.centerYAnchor
            ),
            leadingConstraint,
            trailingConstraint
        ])

        return containerView
    }

    private func makeStatusLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = Constants.statusNumberOfLines
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    private func makeRetryButton() -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = Constants.retryTitle

        return UIButton(
            configuration: configuration,
            primaryAction: UIAction { [weak self] _ in
                self?.loadCategories()
            }
        )
    }

    private func loadCategories() {
        loadTask?.cancel()
        let viewModel = viewModel
        loadTask = Task {
            await viewModel.load()
        }
    }

    private func applySelection() {
        guard viewModel.state == .loaded else {
            return
        }

        onSelection(
            viewModel.appliedCategoryIDs,
            viewModel.categories
        )
        dismiss(animated: true)
    }

}

// MARK: - AnalyticsSheetHeightProviding

extension AnalyticsCategoriesFilterViewController:
    AnalyticsStandardFilterSheetHeightProviding {}

// MARK: - UITableViewDataSource

extension AnalyticsCategoriesFilterViewController: UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        guard
            viewModel.state == .loaded,
            !viewModel.categories.isEmpty
        else {
            return .zero
        }

        return viewModel.categories.count + 1
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: AnalyticsFilterCell.reuseIdentifier,
            for: indexPath
        ) as? AnalyticsFilterCell else {
            return UITableViewCell()
        }
        if indexPath.row == .zero {
            cell.configure(
                title: Constants.allCategoriesTitle,
                isSelected: viewModel.areAllCategoriesSelected
            )
            return cell
        }

        let categoryIndex = indexPath.row - 1
        guard viewModel.categories.indices.contains(categoryIndex) else {
            return cell
        }

        let category = viewModel.categories[categoryIndex]
        cell.configure(
            title: category.name,
            isSelected: viewModel.isSelected(category)
        )
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AnalyticsCategoriesFilterViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == .zero {
            viewModel.toggleAllCategories()
        } else {
            viewModel.toggleCategory(at: indexPath.row - 1)
        }
    }
}
