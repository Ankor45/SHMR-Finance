//
//  TransactionEditorMode.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

enum TransactionEditorMode {
    case creation(
        direction: Direction,
        preferredAccountID: Int?
    )
    case editing(Transaction)
}
