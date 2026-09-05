//
//  AnalyticsSummaryHeaderView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import PieChart
import UIKit

private enum Constants {
    static var incomeTitle: String {
        AppLocalization.string(
            localized: "Доходы за период"
        )
    }
    static var outcomeTitle: String {
        AppLocalization.string(
            localized: "Расходы за период"
        )
    }
    static var totalTitle: String {
        AppLocalization.string(
            localized: "Всего за период"
        )
    }
    static let horizontalInset: CGFloat = 16
    static let verticalInset: CGFloat = 16
    static let minimumContentWidth: CGFloat = 1
}

final class AnalyticsSummaryHeaderView: UIView {
    private let chartView = PieChartView()
    private var hasLoadedChartContent = false
    private var measuredContentWidth: CGFloat?
    private var measuredChartHeight: CGFloat = .zero
    private var minimumChartHeightDuringTransition: CGFloat?
    var onPreferredHeightChange: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        amount: Decimal,
        currencyCode: String,
        chartItems: [AnalyticsChartItem],
        direction: Direction?,
        loadState: AnalyticsLoadState
    ) {
        if loadState == .loading, hasLoadedChartContent {
            return
        }

        let isLoaded = loadState == .loaded
        let totalText = CurrencyPresentation.formattedAmount(
            amount,
            currencyCode: currencyCode
        )
        let entities = isLoaded
            ? chartItems.map {
                PieChart.Entity(value: $0.value, label: $0.label)
            }
            : []
        let previousChartHeight = measuredChartHeight
        let isTransitionActive = chartView.setContent(
            entities: entities,
            totalText: totalText,
            centerTitle: centerTitle(for: direction),
            hidesCenterContent: !isLoaded,
            animated: isLoaded
        )
        minimumChartHeightDuringTransition = isTransitionActive
            && previousChartHeight > .zero
            ? previousChartHeight
            : nil
        hasLoadedChartContent = isLoaded
    }

    func preferredHeight(for containerWidth: CGFloat) -> CGFloat {
        let contentWidth = max(
            containerWidth - Constants.horizontalInset * 2,
            Constants.minimumContentWidth
        )
        let chartHeight = chartView.sizeThatFits(
            CGSize(
                width: contentWidth,
                height: .greatestFiniteMagnitude
            )
        ).height

        let didContentWidthChange = measuredContentWidth.map({
            abs($0 - contentWidth) >= 0.5
        }) ?? true
        if didContentWidthChange {
            measuredContentWidth = contentWidth
            minimumChartHeightDuringTransition = nil
        }
        measuredChartHeight = chartHeight

        let resolvedChartHeight = max(
            chartHeight,
            minimumChartHeightDuringTransition ?? .zero
        )
        return ceil(resolvedChartHeight + Constants.verticalInset * 2)
    }

    private func configureView() {
        backgroundColor = .systemBackground
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.onContentTransitionCompletion = { [weak self] in
            guard let self else {
                return
            }

            self.minimumChartHeightDuringTransition = nil
            self.onPreferredHeightChange?()
        }
        registerForTraitChanges(
            [UITraitPreferredContentSizeCategory.self]
        ) { (view: AnalyticsSummaryHeaderView, _) in
            view.measuredContentWidth = nil
            view.measuredChartHeight = .zero
            view.minimumChartHeightDuringTransition = nil
            view.onPreferredHeightChange?()
        }
        addSubview(chartView)

        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(
                equalTo: topAnchor,
                constant: Constants.verticalInset
            ),
            chartView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: Constants.horizontalInset
            ),
            chartView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -Constants.horizontalInset
            ),
            chartView.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -Constants.verticalInset
            )
        ])
    }

    private func centerTitle(for direction: Direction?) -> String {
        switch direction {
        case .income:
            Constants.incomeTitle
        case .outcome:
            Constants.outcomeTitle
        case nil:
            Constants.totalTitle
        }
    }
}
