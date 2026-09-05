//
//  HTTPMethod.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

nonisolated enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"

    var allowsAutomaticRetry: Bool {
        switch self {
        case .get, .put, .delete:
            true
        case .post, .patch:
            false
        }
    }
}
