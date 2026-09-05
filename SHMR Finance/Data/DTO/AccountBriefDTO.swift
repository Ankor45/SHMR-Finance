//
//  AccountBriefDTO.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

nonisolated struct AccountBriefDTO: Decodable, Sendable {
    let id: Int
    let name: String
    let emoji: String
    let balance: String
    let currency: String
}
