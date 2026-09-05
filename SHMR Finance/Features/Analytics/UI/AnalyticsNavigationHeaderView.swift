//
//  AnalyticsNavigationHeaderView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import UIKit

private enum Constants {
    static var title: String { AppLocalization.string(localized: "Аналитика") }
    static let backIcon = "chevron.left"
    static var backAccessibilityLabel: String {
        AppLocalization.string(
            localized: "Назад"
        )
    }
    static let horizontalInset: CGFloat = 16
    static let backButtonSize: CGFloat = 44
    static let titleSpacing: CGFloat = 12
}

final class AnalyticsNavigationHeaderView: UIView {
    static let preferredHeight: CGFloat = 64

    init(onBack: @escaping () -> Void) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        configureView(onBack: onBack)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView(onBack: @escaping () -> Void) {
        var configuration = UIButton.Configuration.gray()
        configuration.image = UIImage(systemName: Constants.backIcon)
        configuration.cornerStyle = .capsule
        configuration.baseForegroundColor = .label
        configuration.contentInsets = .zero

        let backButton = UIButton(
            configuration: configuration,
            primaryAction: UIAction { _ in onBack() }
        )
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.accessibilityLabel = Constants.backAccessibilityLabel

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = Constants.title
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label
        titleLabel.adjustsFontForContentSizeCategory = true

        addSubview(backButton)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: Constants.horizontalInset
            ),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(
                equalToConstant: Constants.backButtonSize
            ),
            backButton.heightAnchor.constraint(
                equalToConstant: Constants.backButtonSize
            ),
            titleLabel.leadingAnchor.constraint(
                equalTo: backButton.trailingAnchor,
                constant: Constants.titleSpacing
            ),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: trailingAnchor,
                constant: -Constants.horizontalInset
            )
        ])
    }
}
