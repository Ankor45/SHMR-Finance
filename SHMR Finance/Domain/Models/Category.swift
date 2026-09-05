//
//  Category.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 13.07.2026.
//

import Foundation

nonisolated struct Category: Identifiable, Equatable, Sendable {
    let id: Int
    let name: String
    let emoji: Character
    let direction: Direction
}
