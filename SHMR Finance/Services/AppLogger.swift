//
//  AppLogger.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation
import OSLog

nonisolated enum AppLogger {
    private static let subsystem =
        Bundle.main.bundleIdentifier ?? "SHMRFinance"

    static func make(category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }
}
