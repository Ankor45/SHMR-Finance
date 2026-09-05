//
//  TransactionEditorView.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import SwiftUI

private enum Constants {
    static let backgroundColor = Color(.systemBackground)
    static var categoryPlaceholder: String {
        AppLocalization.string(
            localized: "Выберите статью"
        )
    }
    static var accountPlaceholder: String {
        AppLocalization.string(
            localized: "Выберите счёт"
        )
    }
    static var accountLoadingPlaceholder: String {
        AppLocalization.string(
            localized: "Загрузка…"
        )
    }
    static var accountErrorTitle: String {
        AppLocalization.string(
            localized: "Не удалось загрузить счета"
        )
    }
    static var dismissErrorTitle: String { AppLocalization.string(localized: "ОК") }
}

struct TransactionEditorView: View {
    // MARK: - Properties

    @Environment(HapticsService.self) private var hapticsService
    @Environment(\.locale) private var locale
    
    private let categoriesService: any CategoryServiceProviding
    private let onDismiss: () -> Void
    private let onSave: (Transaction) -> Void
    private let onDelete: (Int) -> Void
    private let onCommentBottomChanged: (CGFloat) -> Void

    @Binding private var isCommentEditing: Bool
    
    // MARK: - State
    
    @Bindable private var viewModel: TransactionEditorViewModel
    @State private var inputMode = TransactionEditorInputMode.idle
    @State private var isCategoriesPresented = false
    @State private var isAccountsPresented = false
    @State private var isDeleteConfirmationPresented = false
    @State private var commentFrame = CGRect.zero
    @FocusState private var isCommentFocused: Bool
    
    // MARK: - Initializers
    
    init(
        viewModel: TransactionEditorViewModel,
        categoriesService: any CategoryServiceProviding,
        onDismiss: @escaping () -> Void,
        onSave: @escaping (Transaction) -> Void,
        onDelete: @escaping (Int) -> Void,
        isCommentEditing: Binding<Bool>,
        onCommentBottomChanged: @escaping (CGFloat) -> Void
    ) {
        self.viewModel = viewModel
        self.categoriesService = categoriesService
        self.onDismiss = onDismiss
        self.onSave = onSave
        self.onDelete = onDelete
        _isCommentEditing = isCommentEditing
        self.onCommentBottomChanged = onCommentBottomChanged
    }
    
    // MARK: - View Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: .zero) {
                amountInput
                    .layoutPriority(1)

                ScrollView {
                    information
                }
                .scrollBounceBehavior(.basedOnSize)

                bottomAccessory
                    .safeAreaPadding(.bottom)
            }
            .coordinateSpace(
                name: TransactionEditorCoordinateSpace.editor
            )
            .overlay {
                if isCommentFocused {
                    TransactionEditorInputDismissalOverlay(
                        excludedFrame: commentFrame
                    ) {
                        isCommentFocused = false
                    }
                }
            }
            .background {
                Constants.backgroundColor
                    .contentShape(Rectangle())
                    .onTapGesture(
                        perform: dismissActiveInput
                    )
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(
                Constants.backgroundColor,
                for: .navigationBar
            )
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                TransactionEditorToolbar(
                    isProcessing: viewModel.isProcessing,
                    onDismiss: onDismiss,
                    onConfirm: handleSave
                )
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $isCategoriesPresented) {
            CategoriesListView(
                direction: viewModel.direction,
                service: categoriesService,
                onSelect: selectCategory
            )
        }
        .sheet(isPresented: $isAccountsPresented) {
            TransactionAccountSelectionView(
                accounts: viewModel.accountSelection.accounts,
                selectedAccountID:
                    viewModel.accountSelection.selectedAccount?.id,
                isLoading: viewModel.accountSelection.isLoading,
                loadErrorMessage:
                    viewModel.accountSelection.loadErrorMessage,
                errorMessage:
                    viewModel.accountSelection.errorMessage,
                onSelect: viewModel.accountSelection.select,
                onRetry: viewModel.accountSelection.retry,
                onDismissError:
                    viewModel.accountSelection.dismissError
            )
        }
        .alert(
            Constants.accountErrorTitle,
            isPresented: editorAccountErrorIsPresented
        ) {
            Button(
                Constants.dismissErrorTitle,
                role: .cancel
            ) {}
        } message: {
            Text(
                viewModel.accountSelection.errorMessage
                    ?? String()
            )
        }
        .modifier(
            TransactionEditorAlertsModifier(
                viewModel: viewModel,
                isDeletionPresented:
                    $isDeleteConfirmationPresented,
                onDelete: handleDelete
            )
        )
        .onChange(of: isCommentFocused) { _, isFocused in
            if isFocused {
                inputMode = .idle
            }

            isCommentEditing = isFocused
        }
        .onChange(of: isCommentEditing) { _, isEditing in
            if !isEditing {
                isCommentFocused = false
            }
        }
        .task {
            await viewModel.accountSelection.loadIfNeeded()
        }
    }
    
    // MARK: - Private Properties
    
    private var navigationTitle: String {
        TransactionEditorTitle.value(
            for: viewModel.mode
        )
    }
    
    private var amountInput: some View {
        TransactionEditorAmountView(
            amountText: viewModel.amountText,
            currencyCode: viewModel.currencyCode,
            isActive: inputMode == .amount,
            isDisabled: viewModel.isProcessing,
            onTap: presentKeypad,
            onPaste: viewModel.pasteAmount
        )
    }
    
    private var information: some View {
        TransactionEditorInformationView(
            categoryName:
                viewModel.selectedCategory?.name
                ?? Constants.categoryPlaceholder,
            formattedDate: formattedTransactionDate,
            accountName: accountName,
            transactionDate: transactionDateBinding,
            commentText: commentBinding,
            isCalendarPresented: inputMode == .calendar,
            isProcessing: viewModel.isProcessing,
            isCommentFocused: $isCommentFocused,
            onPresentCategories: presentCategories,
            onPresentCalendar: presentCalendar,
            onPresentAccounts: presentAccounts,
            onDismissCalendar: dismissActiveInput,
            onCommentFramesChanged: handleCommentFramesChanged
        )
    }
    
    private var bottomAccessory: some View {
        TransactionEditorBottomAccessoryView(
            mode: inputMode,
            showsDeleteAction: viewModel.isEditing,
            decimalSeparator: viewModel.decimalSeparator,
            isCommentFocused: isCommentFocused,
            isProcessing: viewModel.isProcessing,
            onDigit: viewModel.appendDigit,
            onDecimalSeparator:
                viewModel.appendDecimalSeparator,
            onDeleteCharacter:
                viewModel.deleteLastCharacter,
            onRequestDeletion: {
                isDeleteConfirmationPresented = true
            }
        )
    }
    
    private var formattedTransactionDate: String {
        viewModel.transactionDate.formatted(
            .dateTime
                .day()
                .month(.wide)
                .hour()
                .minute()
                .locale(locale)
        )
    }

    private var accountName: String {
        if let selectedAccount =
            viewModel.accountSelection.selectedAccount {
            return selectedAccount.name
        }

        return viewModel.accountSelection.isLoading
            ? Constants.accountLoadingPlaceholder
            : Constants.accountPlaceholder
    }

    private var editorAccountErrorIsPresented: Binding<Bool> {
        Binding(
            get: {
                !isAccountsPresented
                    && viewModel.accountSelection.errorMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    viewModel.accountSelection.dismissError()
                }
            }
        )
    }
    
    private var transactionDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.transactionDate },
            set: { viewModel.transactionDate = $0 }
        )
    }
    
    private var commentBinding: Binding<String> {
        Binding(
            get: { viewModel.commentText },
            set: { viewModel.commentText = $0 }
        )
    }
    
    // MARK: - Private Methods
    
    private func presentKeypad() {
        guard !viewModel.isProcessing else {
            return
        }
        
        isCommentFocused = false
        inputMode = .amount
    }
    
    private func presentCategories() {
        isCommentFocused = false
        inputMode = .idle
        isCategoriesPresented = true
    }
    
    private func selectCategory(_ category: Category) {
        viewModel.selectCategory(category)
        inputMode = .idle
    }

    private func presentAccounts() {
        isCommentFocused = false
        inputMode = .idle
        isAccountsPresented = true
    }
    
    private func presentCalendar() {
        isCommentFocused = false
        inputMode = .calendar
    }
    
    private func dismissActiveInput() {
        isCommentFocused = false
        inputMode = .idle
    }

    private func handleCommentFramesChanged(
        _ frames: TransactionEditorCommentFrames
    ) {
        commentFrame = frames.local
        onCommentBottomChanged(frames.global.maxY)
    }

    private func handleSave() {
        Task {
            guard let updatedTransaction = await viewModel.save() else {
                return
            }
            
            onSave(updatedTransaction)
            hapticsService.successOccurred()
            onDismiss()
        }
    }
    
    private func handleDelete() {
        Task {
            guard let transactionID = await viewModel.delete() else {
                return
            }

            onDelete(transactionID)
            onDismiss()
        }
    }
}
