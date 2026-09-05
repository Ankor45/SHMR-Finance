//
//  AnalyticsSectionHeaderView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import UIKit

private enum Constants {
    static let numberOfLines = 0
    static let verticalInset: CGFloat = 14
    static let horizontalInset: CGFloat = 16
}

final class AnalyticsSectionHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "AnalyticsSectionHeaderView"

    // MARK: - Properties

    private let titleLabel = UILabel()

    // MARK: - Initializers

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        configureView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    func configure(title: String) {
        titleLabel.text = title
    }

    // MARK: - Private Methods

    private func configureView() {
        contentView.backgroundColor = .systemBackground

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = Constants.numberOfLines
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: Constants.verticalInset
            ),
            titleLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Constants.horizontalInset
            ),
            titleLabel.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -Constants.horizontalInset
            ),
            titleLabel.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -Constants.verticalInset
            )
        ])
    }
}
