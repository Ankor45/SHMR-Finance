//
//  AnalyticsTransactionCell.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import UIKit

private enum Constants {
    static let lineLimit = 1
    static let emojiSize: CGFloat = 40
    static let emojiCornerRadius: CGFloat = emojiSize / 2
    static let horizontalInset: CGFloat = 16
    static let emojiVerticalInset: CGFloat = 14
    static let contentVerticalInset: CGFloat = 10
    static let contentSpacing: CGFloat = 8
    static let textSpacing: CGFloat = 2
}

final class AnalyticsTransactionCell: UITableViewCell {
    static let reuseIdentifier = "AnalyticsTransactionCell"

    // MARK: - Properties

    private let emojiContainerView = UIView()
    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let commentLabel = UILabel()
    private let amountLabel = UILabel()

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

    func configure(with transaction: Transaction) {
        emojiLabel.text = String(transaction.category.emoji)
        titleLabel.text = transaction.category.name

        let comment = transaction.comment?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        commentLabel.text = comment
        commentLabel.isHidden = comment?.isEmpty != false

        amountLabel.text = CurrencyPresentation.formattedAmount(
            transaction.amount,
            currencyCode: transaction.account.currency
        )

        accessibilityLabel = [
            transaction.category.name,
            comment,
            amountLabel.text
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
    }

    // MARK: - Private Methods

    private func configureView() {
        selectionStyle = .none
        isAccessibilityElement = true

        emojiContainerView.translatesAutoresizingMaskIntoConstraints = false
        emojiContainerView.backgroundColor = .secondarySystemBackground
        emojiContainerView.layer.cornerRadius = Constants.emojiCornerRadius

        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.font = .preferredFont(forTextStyle: .title3)
        emojiLabel.textAlignment = .center
        emojiLabel.adjustsFontForContentSizeCategory = true

        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.textColor = .label
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = Constants.lineLimit

        commentLabel.font = .preferredFont(forTextStyle: .caption1)
        commentLabel.textColor = .secondaryLabel
        commentLabel.adjustsFontForContentSizeCategory = true
        commentLabel.numberOfLines = Constants.lineLimit

        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.font = .preferredFont(forTextStyle: .body)
        amountLabel.textColor = .label
        amountLabel.textAlignment = .right
        amountLabel.adjustsFontForContentSizeCategory = true
        amountLabel.setContentCompressionResistancePriority(
            .required,
            for: .horizontal
        )

        let textStackView = UIStackView(
            arrangedSubviews: [titleLabel, commentLabel]
        )
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        textStackView.axis = .vertical
        textStackView.spacing = Constants.textSpacing

        contentView.addSubview(emojiContainerView)
        emojiContainerView.addSubview(emojiLabel)
        contentView.addSubview(textStackView)
        contentView.addSubview(amountLabel)

        NSLayoutConstraint.activate([
            emojiContainerView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Constants.horizontalInset
            ),
            emojiContainerView.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor
            ),
            emojiContainerView.topAnchor.constraint(
                greaterThanOrEqualTo: contentView.topAnchor,
                constant: Constants.emojiVerticalInset
            ),
            emojiContainerView.bottomAnchor.constraint(
                lessThanOrEqualTo: contentView.bottomAnchor,
                constant: -Constants.emojiVerticalInset
            ),
            emojiContainerView.widthAnchor.constraint(
                equalToConstant: Constants.emojiSize
            ),
            emojiContainerView.heightAnchor.constraint(
                equalToConstant: Constants.emojiSize
            ),

            emojiLabel.centerXAnchor.constraint(
                equalTo: emojiContainerView.centerXAnchor
            ),
            emojiLabel.centerYAnchor.constraint(
                equalTo: emojiContainerView.centerYAnchor
            ),

            textStackView.leadingAnchor.constraint(
                equalTo: emojiContainerView.trailingAnchor,
                constant: Constants.contentSpacing
            ),
            textStackView.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor
            ),
            textStackView.topAnchor.constraint(
                greaterThanOrEqualTo: contentView.topAnchor,
                constant: Constants.contentVerticalInset
            ),
            textStackView.bottomAnchor.constraint(
                lessThanOrEqualTo: contentView.bottomAnchor,
                constant: -Constants.contentVerticalInset
            ),
            textStackView.trailingAnchor.constraint(
                lessThanOrEqualTo: amountLabel.leadingAnchor,
                constant: -Constants.contentSpacing
            ),

            amountLabel.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -Constants.horizontalInset
            ),
            amountLabel.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor
            ),
            amountLabel.topAnchor.constraint(
                greaterThanOrEqualTo: contentView.topAnchor,
                constant: Constants.contentVerticalInset
            ),
            amountLabel.bottomAnchor.constraint(
                lessThanOrEqualTo: contentView.bottomAnchor,
                constant: -Constants.contentVerticalInset
            )
        ])
    }
}
