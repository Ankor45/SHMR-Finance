//
//  TransactionEditorCalendarView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import SwiftUI

private enum Constants {
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 4
    static let bottomPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 14
    static let shadowRadius: CGFloat = 10
    static let shadowY: CGFloat = 4
    static let shadowOpacity = 0.12
}

struct TransactionEditorCalendarView: View {
    // MARK: - Properties

    @Binding private var selectedDate: Date

    private let maximumDate: Date
    private let onDismiss: () -> Void

    // MARK: - Initializers

    init(
        selectedDate: Binding<Date>,
        maximumDate: Date = .now,
        onDismiss: @escaping () -> Void
    ) {
        _selectedDate = selectedDate
        self.maximumDate = maximumDate
        self.onDismiss = onDismiss
    }

    // MARK: - View Body

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: onDismiss)

            calendarSurface
                .padding(
                    .horizontal,
                    Constants.horizontalPadding
                )
                .padding(.top, Constants.verticalPadding)
                .padding(.bottom, Constants.bottomPadding)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Private Properties

    @ViewBuilder
    private var calendarSurface: some View {
        if #available(iOS 26.0, *) {
            calendar
                .glassEffect(
                    .regular,
                    in: RoundedRectangle(
                        cornerRadius: Constants.cornerRadius
                    )
                )
        } else {
            calendar
                .background(
                    Color(.systemBackground),
                    in: RoundedRectangle(
                        cornerRadius: Constants.cornerRadius
                    )
                )
                .shadow(
                    color: Color.black.opacity(
                        Constants.shadowOpacity
                    ),
                    radius: Constants.shadowRadius,
                    y: Constants.shadowY
                )
        }
    }

    private var calendar: some View {
        DatePicker(
            String(),
            selection: $selectedDate,
            in: ...maximumDate,
            displayedComponents: [.date, .hourAndMinute]
        )
        .labelsHidden()
        .datePickerStyle(.graphical)
        .frame(maxWidth: .infinity)
        .contentShape(
            RoundedRectangle(
                cornerRadius: Constants.cornerRadius
            )
        )
    }
}
