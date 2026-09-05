//
//  AnalyticsFilterComponents.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 30.07.2026.
//

import UIKit

private enum Constants {
    static let closeIcon = "xmark"
    static let confirmIcon = "checkmark"
    static var closeAccessibilityLabel: String {
        AppLocalization.string(
            localized: "Закрыть"
        )
    }
    static var confirmAccessibilityLabel: String {
        AppLocalization.string(
            localized: "Применить"
        )
    }
    static let horizontalInset: CGFloat = 16
    static let controlSpacing: CGFloat = 12
    static let buttonSize: CGFloat = 44
    static let titleMinimumScaleFactor: CGFloat = 0.8
}

final class AnalyticsFilterHeaderView: UIView {
    // MARK: - Properties

    var isConfirmationEnabled: Bool {
        get { confirmationButton?.isEnabled ?? false }
        set { confirmationButton?.isEnabled = newValue }
    }

    private var confirmationButton: UIButton?

    // MARK: - Initializers

    init(
        title: String,
        showsConfirmation: Bool = false,
        onClose: @escaping () -> Void,
        onConfirm: (() -> Void)? = nil
    ) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        configureView(
            title: title,
            showsConfirmation: showsConfirmation,
            onClose: onClose,
            onConfirm: onConfirm
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Methods

    private func configureView(
        title: String,
        showsConfirmation: Bool,
        onClose: @escaping () -> Void,
        onConfirm: (() -> Void)?
    ) {
        let titleLabel = makeTitleLabel(title: title)
        let closeButton = makeCloseButton(action: onClose)

        addSubview(titleLabel)
        addSubview(closeButton)

        var constraints = [
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(
                equalToConstant: Constants.buttonSize
            ),
            closeButton.heightAnchor.constraint(
                equalToConstant: Constants.buttonSize
            )
        ]

        if showsConfirmation {
            let confirmationButton = makeConfirmationButton(
                action: onConfirm
            )
            self.confirmationButton = confirmationButton
            addSubview(confirmationButton)

            constraints.append(contentsOf: [
                closeButton.leadingAnchor.constraint(
                    equalTo: leadingAnchor,
                    constant: Constants.horizontalInset
                ),
                titleLabel.leadingAnchor.constraint(
                    greaterThanOrEqualTo: closeButton.trailingAnchor,
                    constant: Constants.controlSpacing
                ),
                titleLabel.trailingAnchor.constraint(
                    lessThanOrEqualTo: confirmationButton.leadingAnchor,
                    constant: -Constants.controlSpacing
                ),
                confirmationButton.trailingAnchor.constraint(
                    equalTo: trailingAnchor,
                    constant: -Constants.horizontalInset
                ),
                confirmationButton.centerYAnchor.constraint(
                    equalTo: centerYAnchor
                ),
                confirmationButton.widthAnchor.constraint(
                    equalToConstant: Constants.buttonSize
                ),
                confirmationButton.heightAnchor.constraint(
                    equalToConstant: Constants.buttonSize
                )
            ])
        } else {
            constraints.append(contentsOf: [
                titleLabel.leadingAnchor.constraint(
                    greaterThanOrEqualTo: leadingAnchor,
                    constant: Constants.horizontalInset
                ),
                titleLabel.trailingAnchor.constraint(
                    lessThanOrEqualTo: closeButton.leadingAnchor,
                    constant: -Constants.controlSpacing
                ),
                closeButton.trailingAnchor.constraint(
                    equalTo: trailingAnchor,
                    constant: -Constants.horizontalInset
                )
            ])
        }

        NSLayoutConstraint.activate(constraints)
    }

    private func makeTitleLabel(title: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = Constants.titleMinimumScaleFactor
        return label
    }

    private func makeCloseButton(
        action: @escaping () -> Void
    ) -> UIButton {
        var configuration = UIButton.Configuration.gray()
        configuration.image = UIImage(systemName: Constants.closeIcon)
        configuration.cornerStyle = .capsule
        configuration.baseForegroundColor = .secondaryLabel
        configuration.contentInsets = .zero

        let button = UIButton(
            configuration: configuration,
            primaryAction: UIAction { _ in action() }
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = Constants.closeAccessibilityLabel
        return button
    }

    private func makeConfirmationButton(
        action: (() -> Void)?
    ) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: Constants.confirmIcon)
        configuration.cornerStyle = .capsule
        configuration.baseForegroundColor = .white
        configuration.contentInsets = .zero

        let button = UIButton(
            configuration: configuration,
            primaryAction: UIAction { _ in action?() }
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = Constants.confirmAccessibilityLabel
        return button
    }
}

final class AnalyticsFilterTableView: UITableView {
    init() {
        super.init(frame: .zero, style: .plain)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemBackground
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = AnalyticsFilterSheetMetrics.rowHeight
        separatorInset = UIEdgeInsets(
            top: .zero,
            left: Constants.horizontalInset,
            bottom: .zero,
            right: Constants.horizontalInset
        )
        register(
            AnalyticsFilterCell.self,
            forCellReuseIdentifier: AnalyticsFilterCell.reuseIdentifier
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class AnalyticsFilterCell: UITableViewCell {
    static let reuseIdentifier = "AnalyticsFilterCell"

    override init(
        style: UITableViewCell.CellStyle,
        reuseIdentifier: String?
    ) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.heightAnchor.constraint(
            greaterThanOrEqualToConstant: AnalyticsFilterSheetMetrics.rowHeight
        ).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, isSelected: Bool) {
        var configuration = defaultContentConfiguration()
        configuration.text = title
        configuration.textProperties.color = .label
        contentConfiguration = configuration
        accessoryType = isSelected ? .checkmark : .none
    }
}
