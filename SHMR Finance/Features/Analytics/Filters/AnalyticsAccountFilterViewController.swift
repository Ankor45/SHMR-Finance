//
//  AnalyticsAccountFilterViewController.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import UIKit

private enum Constants {
    static var title: String { AppLocalization.string(localized: "Счёт") }
    static var allAccountsTitle: String {
        AppLocalization.string(
            localized: "Все счета"
        )
    }
}

final class AnalyticsAccountFilterViewController: UIViewController {
    // MARK: - Properties

    private let accounts: [BankAccount]
    private let selectedAccountID: Int?
    private let onSelection: (Int?) -> Void
    private let tableView = AnalyticsFilterTableView()

    // MARK: - Initializers

    init(
        accounts: [BankAccount],
        selectedAccountID: Int?,
        onSelection: @escaping (Int?) -> Void
    ) {
        self.accounts = accounts
        self.selectedAccountID = selectedAccountID
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

    private func account(at indexPath: IndexPath) -> BankAccount? {
        let accountIndex = indexPath.row - 1
        guard accounts.indices.contains(accountIndex) else {
            return nil
        }

        return accounts[accountIndex]
    }
}

// MARK: - AnalyticsStandardFilterSheetHeightProviding

extension AnalyticsAccountFilterViewController:
    AnalyticsStandardFilterSheetHeightProviding {}

// MARK: - UITableViewDataSource

extension AnalyticsAccountFilterViewController: UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        accounts.count + 1
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

        let account = account(at: indexPath)
        cell.configure(
            title: account?.name ?? Constants.allAccountsTitle,
            isSelected: account?.id == selectedAccountID
        )
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AnalyticsAccountFilterViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelection(account(at: indexPath)?.id)
        dismiss(animated: true)
    }
}
