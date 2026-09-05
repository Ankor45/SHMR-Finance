//
//  NetworkRetryPolicy.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

nonisolated struct NetworkRetryPolicy: Sendable {
    // MARK: - Standard Policy

    static let standard = NetworkRetryPolicy(
        retryableStatusCodes: [
            408,
            429,
            500,
            502,
            503,
            504
        ],
        maxAttempts: 5,
        minimumDelay: 2,
        maximumDelay: 120,
        factor: 1.5,
        jitter: 0.05
    )

    // MARK: - Properties

    let retryableStatusCodes: Set<Int>
    let maxAttempts: Int
    let minimumDelay: TimeInterval
    let maximumDelay: TimeInterval
    let factor: Double
    let jitter: Double

    // MARK: - Initializers

    init(
        retryableStatusCodes: Set<Int>,
        maxAttempts: Int,
        minimumDelay: TimeInterval,
        maximumDelay: TimeInterval,
        factor: Double,
        jitter: Double
    ) {
        precondition(maxAttempts >= 1)
        precondition(minimumDelay >= .zero)
        precondition(maximumDelay >= minimumDelay)
        precondition(factor >= 1)
        precondition((0...1).contains(jitter))

        self.retryableStatusCodes = retryableStatusCodes
        self.maxAttempts = maxAttempts
        self.minimumDelay = minimumDelay
        self.maximumDelay = maximumDelay
        self.factor = factor
        self.jitter = jitter
    }

    // MARK: - Methods

    func shouldRetry(
        statusCode: Int,
        method: HTTPMethod,
        afterAttempt attempt: Int
    ) -> Bool {
        attempt < maxAttempts
            && method.allowsAutomaticRetry
            && retryableStatusCodes.contains(statusCode)
    }

    func delay(
        afterAttempt attempt: Int,
        randomUnitInterval: Double = .random(in: 0...1)
    ) -> TimeInterval {
        let retryIndex = max(0, attempt - 1)
        let exponentialDelay = min(
            maximumDelay,
            minimumDelay * pow(
                factor,
                Double(retryIndex)
            )
        )
        let normalizedRandomValue = min(
            1,
            max(.zero, randomUnitInterval)
        )
        let jitterMultiplier =
            1 + (normalizedRandomValue * 2 - 1) * jitter

        return min(
            maximumDelay,
            max(
                minimumDelay,
                exponentialDelay * jitterMultiplier
            )
        )
    }
}
