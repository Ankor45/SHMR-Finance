//
//  DateBadgeView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 19.07.2026.
//

import SwiftUI

private enum Constants {
    enum Border {
        static let opacity = 0.18
        static let width: CGFloat = 0.5
    }

    static let calendarIcon = "calendar"
    static let spacing: CGFloat = 6
    static let horizontalPadding: CGFloat = 12
    static let height: CGFloat = 36
    static let lineLimit = 1
    static let minimumScaleFactor = 0.75
    static let font = Font.caption.weight(.medium)
}

struct DateBadgeView: View {
    // MARK: - Properties

    @Environment(\.locale) private var locale

    let date: Date
    let isInteractive: Bool
    // MARK: - View Body

    @ViewBuilder
    var body: some View {
        if #available(iOS 26.0, *) {
            if isInteractive {
                content
                    .glassEffect(.regular.interactive(), in: Capsule())
            } else {
                content
                    .glassEffect(.regular, in: Capsule())
            }
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(
                            Color.white.opacity(Constants.Border.opacity),
                            lineWidth: Constants.Border.width
                        )
                }
                .clipShape(Capsule())
        }
    }
    // MARK: - Private Properties

    private var content: some View {
        HStack(spacing: Constants.spacing) {
            Image(systemName: Constants.calendarIcon)

            Text(formattedDate)
                .lineLimit(Constants.lineLimit)
                .minimumScaleFactor(Constants.minimumScaleFactor)
        }
        .font(Constants.font)
        .foregroundStyle(Color.primary)
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(height: Constants.height)
        .contentShape(Capsule())
    }

    private var formattedDate: String {
        date.formatted(
            .dateTime
                .day()
                .month(.wide)
                .locale(locale)
        )
    }
}
