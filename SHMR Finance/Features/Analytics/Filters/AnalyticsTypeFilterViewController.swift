//
//  AnalyticsTypeFilterViewController.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import UIKit

private enum Constants {
    static var title: String { AppLocalization.string(localized: "Тип") }
    static var outcome: String { AppLocalization.string(localized: "Расходы") }
    static var income: String { AppLocalization.string(localized: "Доходы") }
    static var all: String { AppLocalization.string(localized: "Всё") }
}

final class AnalyticsTypeFilterViewController: UIViewController {
    // MARK: - Nested Types

    private enum Option: CaseIterable {
        case outcome
        case income
        case all

        var title: String {
            switch self {
            case .outcome:
                Constants.outcome
            case .income:
                Constants.income
            case .all:
                Constants.all
            }
        }

        var direction: Direction? {
            switch self {
            case .outcome:
                .outcome
            case .income:
                .income
            case .all:
                nil
            }
        }
    }

    // MARK: - Private Properties

    private let selectedDirection: Direction?
    private let onSelection: (Direction?) -> Void
    private let tableView = AnalyticsFilterTableView()

    // MARK: - Initializers

    init(
        selectedDirection: Direction?,
        onSelection: @escaping (Direction?) -> Void
    ) {
        self.selectedDirection = selectedDirection
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

    private func option(at indexPath: IndexPath) -> Option? {
        guard Option.allCases.indices.contains(indexPath.row) else {
            return nil
        }

        return Option.allCases[indexPath.row]
    }
}

// MARK: - AnalyticsSheetHeightProviding

extension AnalyticsTypeFilterViewController:
    AnalyticsStandardFilterSheetHeightProviding {}

// MARK: - UITableViewDataSource

extension AnalyticsTypeFilterViewController: UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        Option.allCases.count
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
            title: option.title,
            isSelected: option.direction == selectedDirection
        )
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AnalyticsTypeFilterViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let option = option(at: indexPath) else {
            return
        }

        onSelection(option.direction)
        dismiss(animated: true)
    }
}
