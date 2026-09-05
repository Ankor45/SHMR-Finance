//
//  AnalyticsDateRangeViewController.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import UIKit

private enum Constants {
    static var title: String { AppLocalization.string(localized: "Период") }
    static let horizontalInset: CGFloat = 16
    static let calendarBottomInset: CGFloat = 12
}

final class AnalyticsDateRangeViewController: UIViewController {
    // MARK: - Private Properties

    private let calendar: Calendar
    private let maximumDate: Date
    private let onSelection: (Date, Date) -> Void
    private let calendarView = UICalendarView()
    private var rangeStartDate: Date?

    // MARK: - Initializers

    init(
        maximumDate: Date = .now,
        calendar: Calendar = .current,
        onSelection: @escaping (Date, Date) -> Void
    ) {
        self.maximumDate = calendar.startOfDay(for: maximumDate)
        self.calendar = calendar
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
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.calendar = calendar
        calendarView.locale = AppLocalization.locale
        calendarView.fontDesign = .rounded
        calendarView.availableDateRange = availableDateRange

        let selection = UICalendarSelectionMultiDate(delegate: self)
        calendarView.selectionBehavior = selection

        view.addSubview(headerView)
        view.addSubview(calendarView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(
                equalToConstant: AnalyticsFilterSheetMetrics.headerHeight
            ),
            calendarView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            calendarView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Constants.horizontalInset
            ),
            calendarView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Constants.horizontalInset
            ),
            calendarView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -Constants.calendarBottomInset
            )
        ])

        calendarView.setVisibleDateComponents(
            calendar.dateComponents([.year, .month], from: maximumDate),
            animated: false
        )
    }

    private var availableDateRange: DateInterval {
        let startDate = calendar.startOfDay(for: .distantPast)
        let endDate = calendar.date(
            byAdding: .day,
            value: 1,
            to: maximumDate
        ) ?? maximumDate

        return DateInterval(start: startDate, end: endDate)
    }

    private func date(from components: DateComponents) -> Date? {
        calendar.date(from: components).map(calendar.startOfDay)
    }

    private func select(_ date: Date) {
        guard let rangeStartDate else {
            rangeStartDate = date
            return
        }

        onSelection(rangeStartDate, date)
        dismiss(animated: true)
    }
}

// MARK: - AnalyticsSheetHeightProviding

extension AnalyticsDateRangeViewController:
    AnalyticsSheetHeightProviding {
    func resolvedSheetHeight(
        containerWidth: CGFloat,
        bottomSafeAreaInset: CGFloat,
        maximumHeight: CGFloat
    ) -> CGFloat {
        let availableWidth = max(
            containerWidth - Constants.horizontalInset * 2,
            1
        )
        let calendarSize = calendarView.sizeThatFits(
            CGSize(
                width: availableWidth,
                height: .greatestFiniteMagnitude
            )
        )
        let contentHeight = AnalyticsFilterSheetMetrics.headerHeight
            + calendarSize.height
            + Constants.calendarBottomInset
            + bottomSafeAreaInset

        return min(ceil(contentHeight), maximumHeight)
    }
}

// MARK: - UICalendarSelectionMultiDateDelegate

extension AnalyticsDateRangeViewController:
    UICalendarSelectionMultiDateDelegate {
    func multiDateSelection(
        _ selection: UICalendarSelectionMultiDate,
        canSelectDate dateComponents: DateComponents
    ) -> Bool {
        guard let date = date(from: dateComponents) else {
            return false
        }

        return date <= maximumDate
    }

    func multiDateSelection(
        _ selection: UICalendarSelectionMultiDate,
        didSelectDate dateComponents: DateComponents
    ) {
        guard let date = date(from: dateComponents) else {
            return
        }

        select(date)
    }

    func multiDateSelection(
        _ selection: UICalendarSelectionMultiDate,
        didDeselectDate dateComponents: DateComponents
    ) {
        guard
            rangeStartDate != nil,
            let date = date(from: dateComponents)
        else {
            return
        }

        select(date)
    }
}
