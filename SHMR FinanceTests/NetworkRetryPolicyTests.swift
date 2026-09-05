//
//  NetworkRetryPolicyTests.swift
//  SHMR FinanceTests
//
//  Created by Andrei Kovryzhenko on 04.09.2026.
//

import Foundation
import Testing
@testable import SHMR_Finance

struct NetworkRetryPolicyTests {
    // MARK: - Retry Decision

    @Test func shouldRetry_requiresRetryableMethodAndStatus() {
        let policy = makePolicy()

        for method in [HTTPMethod.get, .put, .delete] {
            #expect(
                policy.shouldRetry(
                    statusCode: 500,
                    method: method,
                    afterAttempt: 1
                )
            )
        }

        for method in [HTTPMethod.post, .patch] {
            #expect(
                !policy.shouldRetry(
                    statusCode: 500,
                    method: method,
                    afterAttempt: 1
                )
            )
        }

        #expect(
            !policy.shouldRetry(
                statusCode: 400,
                method: .get,
                afterAttempt: 1
            )
        )
    }

    @Test func shouldRetry_stopsAtMaximumAttemptCount() {
        let policy = makePolicy()

        #expect(
            policy.shouldRetry(
                statusCode: 500,
                method: .get,
                afterAttempt: 2
            )
        )
        #expect(
            !policy.shouldRetry(
                statusCode: 500,
                method: .get,
                afterAttempt: 3
            )
        )
    }

    // MARK: - Retry Delay

    @Test func delay_usesExponentialBackoff() {
        let policy = makePolicy(jitter: .zero)

        #expect(policy.delay(afterAttempt: 1) == 2)
        #expect(policy.delay(afterAttempt: 2) == 4)
        #expect(policy.delay(afterAttempt: 3) == 8)
    }

    @Test func delay_appliesJitterAndMaximumLimit() {
        let policy = makePolicy(jitter: 0.25)

        #expect(
            policy.delay(
                afterAttempt: 2,
                randomUnitInterval: .zero
            ) == 3
        )
        #expect(
            policy.delay(
                afterAttempt: 2,
                randomUnitInterval: 1
            ) == 5
        )
        #expect(
            policy.delay(
                afterAttempt: 10,
                randomUnitInterval: 1
            ) == 10
        )
    }

    // MARK: - Private Methods

    private func makePolicy(
        jitter: Double = .zero
    ) -> NetworkRetryPolicy {
        NetworkRetryPolicy(
            retryableStatusCodes: [500],
            maxAttempts: 3,
            minimumDelay: 2,
            maximumDelay: 10,
            factor: 2,
            jitter: jitter
        )
    }
}
