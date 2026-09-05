//
//  AnalyticsViewController.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 29.07.2026.
//

import UIKit

final class AnalyticsViewController: UIViewController {
    // MARK: - Properties

    var onBack: () -> Void
    let viewModel: AnalyticsViewModel
    private let tableView = UITableView(frame: .zero, style: .plain)
    let sheetTransitioningDelegate =
        AnalyticsBottomSheetTransitioningDelegate()
    private var tableAdapter: AnalyticsTableAdapter?
    private var loadTask: Task<Void, Never>?
    var accountFilterTask: Task<Void, Never>?

    // MARK: - Initializers

    init(
        initialDirection: Direction,
        service: any TransactionsScreenServiceProviding,
        accountsStore: AccountsStore,
        onBack: @escaping () -> Void
    ) {
        self.onBack = onBack
        viewModel = AnalyticsViewModel(
            initialDirection: initialDirection,
            service: service,
            accountsStore: accountsStore
        )
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
        configureTableAdapter()
        viewModel.onChange = { [weak self] in
            self?.render()
        }
        loadTransactions()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableAdapter?.layoutSummaryHeaderIfNeeded()
    }

    // MARK: - Methods

    func stopLoading() {
        loadTask?.cancel()
        loadTask = nil
        accountFilterTask?.cancel()
        accountFilterTask = nil
        viewModel.cancelLoading()
        viewModel.onChange = nil
    }

    func loadTransactions() {
        loadTask?.cancel()
        let viewModel = viewModel
        viewModel.beginLoading()
        loadTask = Task {
            await viewModel.loadTransactions()
        }
    }

    // MARK: - Private Methods

    private func configureView() {
        view.backgroundColor = .systemBackground

        let headerView = AnalyticsNavigationHeaderView(
            onBack: { [weak self] in
                self?.close()
            }
        )
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            headerView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            headerView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            headerView.heightAnchor.constraint(
                equalToConstant: AnalyticsNavigationHeaderView.preferredHeight
            ),
            tableView.topAnchor.constraint(
                equalTo: headerView.bottomAnchor
            ),
            tableView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            tableView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            tableView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            )
        ])
    }

    private func configureTableAdapter() {
        tableAdapter = AnalyticsTableAdapter(
            tableView: tableView,
            onRetry: { [weak self] in
                self?.loadTransactions()
            },
            onFilterSelection: { [weak self] filter in
                self?.handleFilterSelection(filter)
            }
        )
    }

    private func render() {
        tableAdapter?.render(viewModel.viewState)
    }

    private func close() {
        stopLoading()
        onBack()
    }
}
