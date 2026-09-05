//
//  AnalyticsTableAdapter.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import UIKit

private enum Constants {
    static var transactionsTitle: String {
        AppLocalization.string(
            localized: "Транзакции"
        )
    }
    static let filterCellIdentifier = "AnalyticsMainFilterCell"
    static let horizontalInset: CGFloat = 16
    static let transactionSeparatorInset: CGFloat = 64
    static let estimatedRowHeight: CGFloat = 68
    static let estimatedSectionHeaderHeight: CGFloat = 52
}

nonisolated private enum AnalyticsSection: Hashable {
    case filters
    case transactions
}

nonisolated enum AnalyticsFilterRow: CaseIterable, Hashable {
    case type
    case period
    case categories
    case account
    case sorting
}

nonisolated private enum AnalyticsItem: Hashable {
    case filter(AnalyticsFilterRow)
    case transaction(Int)
    case status(AnalyticsTableStatus)
}

@MainActor
final class AnalyticsTableAdapter: NSObject {
    // MARK: - Properties

    private weak var tableView: UITableView?
    private let summaryHeaderView = AnalyticsSummaryHeaderView()
    private let filterFormatter = AnalyticsFilterFormatter()
    private let onRetry: () -> Void
    private let onFilterSelection: (AnalyticsFilterRow) -> Void
    private var dataSource:
        UITableViewDiffableDataSource<AnalyticsSection, AnalyticsItem>?
    private var transactionsByID: [Int: Transaction] = [:]
    private var filterValues: [AnalyticsFilterRow: String] = [:]

    // MARK: - Initializers

    init(
        tableView: UITableView,
        onRetry: @escaping () -> Void,
        onFilterSelection: @escaping (AnalyticsFilterRow) -> Void
    ) {
        self.tableView = tableView
        self.onRetry = onRetry
        self.onFilterSelection = onFilterSelection
        super.init()
        summaryHeaderView.onPreferredHeightChange = { [weak self] in
            self?.layoutSummaryHeaderIfNeeded()
        }
        configure(tableView)
        configureDataSource(for: tableView)
    }

    // MARK: - Public Methods

    func render(_ viewState: AnalyticsViewState) {
        filterValues = filterFormatter.values(for: viewState)
        summaryHeaderView.configure(
            amount: viewState.totalAmount,
            currencyCode: viewState.currencyCode,
            chartItems: viewState.chartItems,
            direction: viewState.filters.direction,
            loadState: viewState.loadState
        )
        layoutSummaryHeaderIfNeeded()

        let visibleTransactions = viewState.transactions
        transactionsByID = Dictionary(
            uniqueKeysWithValues: visibleTransactions.map {
                ($0.id, $0)
            }
        )

        var snapshot = NSDiffableDataSourceSnapshot<
            AnalyticsSection,
            AnalyticsItem
        >()
        snapshot.appendSections([.filters, .transactions])
        let filterItems = AnalyticsFilterRow.allCases.map(
            AnalyticsItem.filter
        )
        let existingItems = Set(
            dataSource?.snapshot().itemIdentifiers ?? []
        )
        snapshot.appendItems(filterItems, toSection: .filters)
        snapshot.reconfigureItems(
            filterItems.filter(existingItems.contains)
        )
        let transactionItems = transactionItems(
            state: viewState.loadState,
            transactions: visibleTransactions
        )
        snapshot.appendItems(transactionItems, toSection: .transactions)
        snapshot.reconfigureItems(
            transactionItems.filter(existingItems.contains)
        )
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    func layoutSummaryHeaderIfNeeded() {
        guard
            let tableView,
            tableView.bounds.width > .zero
        else {
            return
        }

        let width = tableView.bounds.width
        let height = summaryHeaderView.preferredHeight(for: width)
        guard height > .zero else {
            return
        }

        let targetFrame = CGRect(
            x: .zero,
            y: .zero,
            width: width,
            height: height
        )
        let needsAssignment = tableView.tableHeaderView !== summaryHeaderView
            || summaryHeaderView.frame.size != targetFrame.size

        guard needsAssignment else {
            return
        }

        summaryHeaderView.frame = targetFrame
        tableView.tableHeaderView = summaryHeaderView
        summaryHeaderView.layoutIfNeeded()
    }

    // MARK: - Private Methods

    private func configure(_ tableView: UITableView) {
        tableView.backgroundColor = .systemBackground
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight =
            Constants.estimatedSectionHeaderHeight
        tableView.sectionHeaderTopPadding = .zero
        tableView.separatorColor = .separator
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: Constants.filterCellIdentifier
        )
        tableView.register(
            AnalyticsTransactionCell.self,
            forCellReuseIdentifier:
                AnalyticsTransactionCell.reuseIdentifier
        )
        tableView.register(
            AnalyticsStatusCell.self,
            forCellReuseIdentifier: AnalyticsStatusCell.reuseIdentifier
        )
        tableView.register(
            AnalyticsSectionHeaderView.self,
            forHeaderFooterViewReuseIdentifier:
                AnalyticsSectionHeaderView.reuseIdentifier
        )
    }

    private func configureDataSource(for tableView: UITableView) {
        dataSource = UITableViewDiffableDataSource<
            AnalyticsSection,
            AnalyticsItem
        >(tableView: tableView) { [weak self] tableView, indexPath, item in
            guard let self else {
                return UITableViewCell()
            }

            return switch item {
            case .filter(let filter):
                makeFilterCell(
                    tableView: tableView,
                    indexPath: indexPath,
                    filter: filter
                )
            case .transaction(let transactionID):
                makeTransactionCell(
                    tableView: tableView,
                    indexPath: indexPath,
                    transactionID: transactionID
                )
            case .status(let status):
                makeStatusCell(
                    tableView: tableView,
                    indexPath: indexPath,
                    status: status
                )
            }
        }
    }

    private func transactionItems(
        state: AnalyticsLoadState,
        transactions: [Transaction]
    ) -> [AnalyticsItem] {
        switch state {
        case .loading:
            [.status(.loading)]
        case .loaded where transactions.isEmpty:
            [.status(.empty)]
        case .loaded:
            transactions.map { .transaction($0.id) }
        case .failed(let message):
            [.status(.error(message))]
        }
    }

    private func makeFilterCell(
        tableView: UITableView,
        indexPath: IndexPath,
        filter: AnalyticsFilterRow
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Constants.filterCellIdentifier,
            for: indexPath
        )
        var configuration = cell.defaultContentConfiguration()
        configuration.text = filterFormatter.title(for: filter)
        configuration.secondaryText = filterValues[filter]
        configuration.prefersSideBySideTextAndSecondaryText = true
        configuration.textProperties.color = .label
        configuration.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = configuration
        cell.selectionStyle = .default
        cell.separatorInset = standardSeparatorInset
        return cell
    }

    private func makeTransactionCell(
        tableView: UITableView,
        indexPath: IndexPath,
        transactionID: Int
    ) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: AnalyticsTransactionCell.reuseIdentifier,
                for: indexPath
            ) as? AnalyticsTransactionCell,
            let transaction = transactionsByID[transactionID]
        else {
            return UITableViewCell()
        }

        cell.configure(with: transaction)
        cell.separatorInset = UIEdgeInsets(
            top: .zero,
            left: Constants.transactionSeparatorInset,
            bottom: .zero,
            right: Constants.horizontalInset
        )
        return cell
    }

    private func makeStatusCell(
        tableView: UITableView,
        indexPath: IndexPath,
        status: AnalyticsTableStatus
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: AnalyticsStatusCell.reuseIdentifier,
            for: indexPath
        ) as? AnalyticsStatusCell else {
            return UITableViewCell()
        }

        cell.configure(status: status)
        cell.onRetry = onRetry
        cell.separatorInset = standardSeparatorInset
        return cell
    }

    private var standardSeparatorInset: UIEdgeInsets {
        UIEdgeInsets(
            top: .zero,
            left: Constants.horizontalInset,
            bottom: .zero,
            right: Constants.horizontalInset
        )
    }

}

// MARK: - UITableViewDelegate

extension AnalyticsTableAdapter: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        guard
            let item = dataSource?.itemIdentifier(for: indexPath),
            case .filter(let filter) = item
        else {
            return
        }

        onFilterSelection(filter)
    }

    func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        sectionIdentifier(at: section) == .transactions
            ? UITableView.automaticDimension
            : .leastNormalMagnitude
    }

    func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        guard sectionIdentifier(at: section) == .transactions else {
            return nil
        }

        guard let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: AnalyticsSectionHeaderView.reuseIdentifier
        ) as? AnalyticsSectionHeaderView else {
            return nil
        }
        header.configure(title: Constants.transactionsTitle)
        return header
    }

    private func sectionIdentifier(at index: Int) -> AnalyticsSection? {
        let sections = dataSource?.snapshot().sectionIdentifiers ?? []
        guard sections.indices.contains(index) else {
            return nil
        }

        return sections[index]
    }
}
