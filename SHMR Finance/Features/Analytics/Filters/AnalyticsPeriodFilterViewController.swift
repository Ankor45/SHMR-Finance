//
//  AnalyticsPeriodFilterViewController.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import UIKit

private enum Constants {
    static var title: String { AppLocalization.string(localized: "Период") }
    static var custom: String { AppLocalization.string(localized: "Произвольный") }
    static var week: String { AppLocalization.string(localized: "За неделю") }
    static var month: String { AppLocalization.string(localized: "За месяц") }
    static var quarter: String { AppLocalization.string(localized: "За квартал") }
    static var year: String { AppLocalization.string(localized: "За год") }
}

final class AnalyticsPeriodFilterViewController: UIViewController {
    // MARK: - Nested Types

    private enum Option: CaseIterable, Equatable {
        case custom
        case week
        case month
        case quarter
        case year

        var title: String {
            switch self {
            case .custom:
                Constants.custom
            case .week:
                Constants.week
            case .month:
                Constants.month
            case .quarter:
                Constants.quarter
            case .year:
                Constants.year
            }
        }

        var dateComponent: DateComponents? {
            switch self {
            case .custom:
                nil
            case .week:
                DateComponents(day: -6)
            case .month:
                DateComponents(month: -1)
            case .quarter:
                DateComponents(month: -3)
            case .year:
                DateComponents(year: -1)
            }
        }
    }

    // MARK: - Private Properties

    private let startDate: Date
    private let endDate: Date
    private let referenceDate: Date
    private let calendar: Calendar
    private let onSelection: (Date, Date) -> Void
    private let onCustomSelection: () -> Void
    private let tableView = AnalyticsFilterTableView()

    // MARK: - Initializers

    init(
        startDate: Date,
        endDate: Date,
        referenceDate: Date = .now,
        calendar: Calendar = .current,
        onSelection: @escaping (Date, Date) -> Void,
        onCustomSelection: @escaping () -> Void
    ) {
        self.startDate = calendar.startOfDay(for: startDate)
        self.endDate = calendar.startOfDay(for: endDate)
        self.referenceDate = calendar.startOfDay(for: referenceDate)
        self.calendar = calendar
        self.onSelection = onSelection
        self.onCustomSelection = onCustomSelection
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

    // MARK: - Private Properties

    private var selectedOption: Option {
        Option.allCases
            .dropFirst()
            .first(where: matchesCurrentPeriod) ?? .custom
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

    private func matchesCurrentPeriod(_ option: Option) -> Bool {
        guard let dateComponent = option.dateComponent else {
            return false
        }
        guard let expectedStartDate = calendar.date(
                byAdding: dateComponent,
                to: referenceDate
            ) else {
            return false
        }

        return calendar.isDate(startDate, inSameDayAs: expectedStartDate)
            && calendar.isDate(endDate, inSameDayAs: referenceDate)
    }

    private func select(_ option: Option) {
        guard let dateComponent = option.dateComponent else {
            dismiss(animated: true, completion: onCustomSelection)
            return
        }

        guard let selectedStartDate = calendar.date(
            byAdding: dateComponent,
            to: referenceDate
        ) else {
            return
        }

        onSelection(selectedStartDate, referenceDate)
        dismiss(animated: true)
    }
}

// MARK: - AnalyticsSheetHeightProviding

extension AnalyticsPeriodFilterViewController:
    AnalyticsStandardFilterSheetHeightProviding {}

// MARK: - UITableViewDataSource

extension AnalyticsPeriodFilterViewController: UITableViewDataSource {
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
            isSelected: option == selectedOption
        )
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AnalyticsPeriodFilterViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let option = option(at: indexPath) else {
            return
        }

        select(option)
    }
}
