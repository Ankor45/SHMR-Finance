//
//  PersistenceDecimalCodec.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation

nonisolated enum PersistenceDecimalCodec {
    static func string(from decimal: Decimal) -> String {
        NSDecimalNumber(decimal: decimal).stringValue
    }

    static func decimal(from string: String) -> Decimal? {
        Decimal(string: string, locale: AppLocale.posix)
    }
}

nonisolated struct AccountBalanceDeltaSnapshot: Codable, Sendable {
    let accountId: Int
    let amount: String
}
