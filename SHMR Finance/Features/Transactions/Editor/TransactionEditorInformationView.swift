//
//  TransactionEditorInformationView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import SwiftUI

private enum Constants {
    static var categoryTitle: String { AppLocalization.string(localized: "Статья") }
    static var dateTitle: String { AppLocalization.string(localized: "Дата и время") }
    static var accountTitle: String { AppLocalization.string(localized: "Счёт") }
    static var commentPrompt: String {
        AppLocalization.string(
            localized: "Комментарий"
        )
    }
    static let rowHeight: CGFloat = 50
    static let horizontalPadding: CGFloat = 16
    static let valueLineLimit = 1
}

struct TransactionEditorInformationView: View {
    // MARK: - Properties

    @Binding private var transactionDate: Date
    @Binding private var commentText: String

    private let categoryName: String
    private let formattedDate: String
    private let accountName: String
    private let isCalendarPresented: Bool
    private let isProcessing: Bool
    private let isCommentFocused: FocusState<Bool>.Binding
    private let onPresentCategories: () -> Void
    private let onPresentCalendar: () -> Void
    private let onPresentAccounts: () -> Void
    private let onDismissCalendar: () -> Void
    private let onCommentFramesChanged:
        (TransactionEditorCommentFrames) -> Void

    // MARK: - Initializers

    init(
        categoryName: String,
        formattedDate: String,
        accountName: String,
        transactionDate: Binding<Date>,
        commentText: Binding<String>,
        isCalendarPresented: Bool,
        isProcessing: Bool,
        isCommentFocused: FocusState<Bool>.Binding,
        onPresentCategories: @escaping () -> Void,
        onPresentCalendar: @escaping () -> Void,
        onPresentAccounts: @escaping () -> Void,
        onDismissCalendar: @escaping () -> Void,
        onCommentFramesChanged:
            @escaping (TransactionEditorCommentFrames) -> Void
    ) {
        self.categoryName = categoryName
        self.formattedDate = formattedDate
        self.accountName = accountName
        _transactionDate = transactionDate
        _commentText = commentText
        self.isCalendarPresented = isCalendarPresented
        self.isProcessing = isProcessing
        self.isCommentFocused = isCommentFocused
        self.onPresentCategories = onPresentCategories
        self.onPresentCalendar = onPresentCalendar
        self.onPresentAccounts = onPresentAccounts
        self.onDismissCalendar = onDismissCalendar
        self.onCommentFramesChanged = onCommentFramesChanged
    }

    // MARK: - View Body

    var body: some View {
        VStack(spacing: .zero) {
            separator

            categoryRow

            separator

            if isCalendarPresented {
                calendar
            } else {
                details
            }
        }
    }

    // MARK: - Private Properties

    private var categoryRow: some View {
        informationButton(
            title: Constants.categoryTitle,
            value: categoryName,
            action: handleCategoryTap
        )
    }

    private var calendar: some View {
        TransactionEditorCalendarView(
            selectedDate: $transactionDate,
            onDismiss: onDismissCalendar
        )
    }

    private var details: some View {
        VStack(spacing: .zero) {
            informationButton(
                title: Constants.dateTitle,
                value: formattedDate,
                action: onPresentCalendar
            )

            separator
            accountRow
            separator

            VStack(spacing: .zero) {
                commentInput
                separator
            }
        }
    }

    private var accountRow: some View {
        informationButton(
            title: Constants.accountTitle,
            value: accountName,
            action: onPresentAccounts
        )
    }

    private var commentInput: some View {
        TextField(
            Constants.commentPrompt,
            text: $commentText
        )
        .focused(isCommentFocused)
        .lineLimit(1)
        .submitLabel(.done)
        .onSubmit {
            isCommentFocused.wrappedValue = false
        }
        .frame(minHeight: Constants.rowHeight)
        .padding(.horizontal, Constants.horizontalPadding)
        .onGeometryChange(
            for: TransactionEditorCommentFrames.self
        ) { proxy in
            TransactionEditorCommentFrames(
                local: proxy.frame(
                    in: .named(
                        TransactionEditorCoordinateSpace.editor
                    )
                ),
                global: proxy.frame(in: .global)
            )
        } action: { frames in
            onCommentFramesChanged(frames)
        }
    }

    private var separator: some View {
        Divider()
            .padding(.horizontal, Constants.horizontalPadding)
    }

    // MARK: - Private Methods

    private func handleCategoryTap() {
        if isCalendarPresented {
            onDismissCalendar()
        } else {
            onPresentCategories()
        }
    }

    private func informationRow(
        title: String,
        value: String
    ) -> some View {
        HStack {
            Text(title)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
                .lineLimit(Constants.valueLineLimit)
        }
        .frame(minHeight: Constants.rowHeight)
        .padding(.horizontal, Constants.horizontalPadding)
    }

    private func informationButton(
        title: String,
        value: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            informationRow(title: title, value: value)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
    }
}
