//
//  DateSelectionButton.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 18.07.2026.
//

import SwiftUI

private enum Constants {
    static var accessibilityLabel: String {
        AppLocalization.string(
            localized: "Выбрать дату"
        )
    }
}

struct DateSelectionButton: View {
    // MARK: - Properties
    @Environment(\.locale) private var locale

    @Binding var selectedDate: Date
    
    // MARK: - View Body
    var body: some View {
        DateBadgeView(date: selectedDate, isInteractive: true)
            .frame(minHeight: 44)
            .accessibilityHidden(true)
            .overlay {
                datePicker
            }
    }

    // MARK: - Private Properties

    private var datePicker: some View {
        DatePicker(
            Constants.accessibilityLabel,
            selection: $selectedDate,
            in: ...Date.now,
            displayedComponents: .date
        )
        .datePickerStyle(.compact)
        .labelsHidden()
        .environment(\.locale, locale)
        .id(locale.identifier)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Capsule())
        .colorMultiply(.clear)
        .allowsHitTesting(true)
        .accessibilityLabel(Constants.accessibilityLabel)
        .accessibilityValue(formattedAccessibilityDate)
    }
    
    private var formattedAccessibilityDate: String {
        selectedDate.formatted(
            .dateTime
                .day()
                .month(.wide)
                .year()
                .locale(locale)
        )
    }
}
