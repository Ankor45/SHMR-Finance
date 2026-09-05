//
//  TransactionEditorCommentFrames.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import CoreGraphics

nonisolated struct TransactionEditorCommentFrames:
    Equatable,
    Sendable {
    let local: CGRect
    let global: CGRect
}
