//
//  NetworkRequest.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

nonisolated struct NetworkRequest: Sendable {
    // MARK: - Public Properties

    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]
    let headers: [String: String]

    // MARK: - Initializers

    init(
        path: String,
        method: HTTPMethod,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:]
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
    }
}
