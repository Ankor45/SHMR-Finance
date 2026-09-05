//
//  TransactionEditorRoute.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

struct TransactionEditorRoute: Identifiable {
    let id = UUID()
    let mode: TransactionEditorMode
    let onSave: (Transaction) -> Void
    let onDelete: (Int) -> Void
}
