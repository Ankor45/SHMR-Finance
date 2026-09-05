//
//  AnalyticsSortingFilterViewController.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import UIKit

private enum Constants {
    static var title: String { AppLocalization.string(localized: "Сортировка") }
    static var byDate: String { AppLocalization.string(localized: "По дате") }
    static var byAmount: String { AppLocalization.string(localized: "По сумме") }
}

final class AnalyticsSortingFilterViewController: UIViewController {
    // MARK: - Properties

    private let selectedOption: AnalyticsSortOption
    private let onSelection: (AnalyticsSortOption) -> Void
    private let tableView = AnalyticsFilterTableView()

    // MARK: - Initializers

    init(
        selectedOption: AnalyticsSortOption,
        onSelection: @escaping (AnalyticsSortOption) -> Void
    ) {
        self.selectedOption = selectedOption
        self.onSelection = onSelection
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    // MARK: - Private Methods

    private func configureView() {
        view.backgroundColor = .systemBackground

        let headerView = AnalyticsFilterHeaderView(
            title: Constants.title,
            onClose: { [weak self] in
                self?.dismiss(animated: true)
            }
        )
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

    private func option(at indexPath: IndexPath) -> AnalyticsSortOption? {
        guard AnalyticsSortOption.allCases.indices.contains(indexPath.row) else {
            return nil
        }

        return AnalyticsSortOption.allCases[indexPath.row]
    }

    private func title(for option: AnalyticsSortOption) -> String {
        switch option {
        case .date:
            Constants.byDate
        case .amount:
            Constants.byAmount
        }
    }
}

// MARK: - AnalyticsStandardFilterSheetHeightProviding

extension AnalyticsSortingFilterViewController:
    AnalyticsStandardFilterSheetHeightProviding {}

// MARK: - UITableViewDataSource

extension AnalyticsSortingFilterViewController: UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        AnalyticsSortOption.allCases.count
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
        guard let option = option(at: indexPath) else {
            return cell
        }

        cell.configure(
            title: title(for: option),
            isSelected: option == selectedOption
        )
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AnalyticsSortingFilterViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let option = option(at: indexPath) else {
            return
        }

        onSelection(option)
        dismiss(animated: true)
    }
}
