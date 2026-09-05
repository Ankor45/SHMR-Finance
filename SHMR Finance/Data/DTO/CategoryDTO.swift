//
//  CategoryDTO.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 15.07.2026.
//

import Foundation

nonisolated struct CategoryDTO: Decodable, Sendable {
    let id: Int
    let name: String
    let emoji: String
    let isIncome: Bool
}
