//
//  AnalyticsStatusCell.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import UIKit

private enum Constants {
    static var loadingMessage: String {
        AppLocalization.string(
            localized: "Загрузка операций…"
        )
    }
    static var emptyMessage: String {
        AppLocalization.string(
            localized: "За выбранный период операций нет"
        )
    }
    static var retryTitle: String { AppLocalization.string(localized: "Повторить") }
    static let messageNumberOfLines = 0
    static let spacing: CGFloat = 12
    static let contentInset: CGFloat = 24
}

nonisolated enum AnalyticsTableStatus: Hashable {
    case loading
    case empty
    case error(String)
}

final class AnalyticsStatusCell: UITableViewCell {
    static let reuseIdentifier = "AnalyticsStatusCell"

    // MARK: - Properties

    var onRetry: (() -> Void)?

    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    // MARK: - Initializers

    override init(
        style: UITableViewCell.CellStyle,
        reuseIdentifier: String?
    ) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    func configure(status: AnalyticsTableStatus) {
        switch status {
        case .loading:
            messageLabel.text = Constants.loadingMessage
            activityIndicator.startAnimating()
            retryButton.isHidden = true
        case .empty:
            messageLabel.text = Constants.emptyMessage
            activityIndicator.stopAnimating()
            retryButton.isHidden = true
        case .error(let message):
            messageLabel.text = message
            activityIndicator.stopAnimating()
            retryButton.isHidden = false
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onRetry = nil
        activityIndicator.stopAnimating()
    }

    // MARK: - Actions

    @objc
    private func retryButtonTapped() {
        onRetry?()
    }

    // MARK: - Private Methods

    private func configureView() {
        selectionStyle = .none

        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = Constants.messageNumberOfLines
        messageLabel.adjustsFontForContentSizeCategory = true

        retryButton.setTitle(Constants.retryTitle, for: .normal)
        retryButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        retryButton.addTarget(
            self,
            action: #selector(retryButtonTapped),
            for: .touchUpInside
        )

        let stackView = UIStackView(
            arrangedSubviews: [
                activityIndicator,
                messageLabel,
                retryButton
            ]
        )
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Constants.spacing

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentView.leadingAnchor,
                constant: Constants.contentInset
            ),
            stackView.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor,
                constant: -Constants.contentInset
            ),
            stackView.centerXAnchor.constraint(
                equalTo: contentView.centerXAnchor
            ),
            stackView.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor
            ),
            stackView.topAnchor.constraint(
                greaterThanOrEqualTo: contentView.topAnchor,
                constant: Constants.contentInset
            ),
            stackView.bottomAnchor.constraint(
                lessThanOrEqualTo: contentView.bottomAnchor,
                constant: -Constants.contentInset
            )
        ])
    }
}
