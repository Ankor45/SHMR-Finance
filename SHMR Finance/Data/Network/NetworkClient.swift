//
//  NetworkClient.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 25.07.2026.
//

import Foundation

private nonisolated enum Constants {
    static let authorizationHeader = "Authorization"
    static let acceptHeader = "Accept"
    static let contentTypeHeader = "Content-Type"
    static let jsonContentType = "application/json"
    static let bearerPrefix = "Bearer "
    static let successfulStatusCodes = 200...299
}

nonisolated final class NetworkClient: Sendable {
    // MARK: - Private Properties

    private let baseURL: URL
    private let token: String
    private let session: URLSession
    private let retryPolicy: NetworkRetryPolicy

    // MARK: - Initializers

    init(
        baseURL: URL,
        token: String,
        session: URLSession = .shared,
        retryPolicy: NetworkRetryPolicy = .standard
    ) {
        self.baseURL = baseURL
        self.token = token
        self.session = session
        self.retryPolicy = retryPolicy
    }

    // MARK: - Public Methods

    func request<Response>(
        _ request: NetworkRequest,
        responseType: Response.Type = Response.self
    ) async throws -> Response
    where Response: Decodable & Sendable {
        let data = try await perform(request, body: nil)
        return try decode(responseType, from: data)
    }

    func request<Body, Response>(
        _ request: NetworkRequest,
        body: Body,
        responseType: Response.Type = Response.self
    ) async throws -> Response
    where Body: Encodable & Sendable,
          Response: Decodable & Sendable {
        let encodedBody = try encode(body)
        let data = try await perform(
            request,
            body: encodedBody
        )
        return try decode(responseType, from: data)
    }

    func request(_ request: NetworkRequest) async throws {
        _ = try await perform(request, body: nil)
    }

    func request<Body>(
        _ request: NetworkRequest,
        body: Body
    ) async throws
    where Body: Encodable & Sendable {
        let encodedBody = try encode(body)
        _ = try await perform(
            request,
            body: encodedBody
        )
    }

    // MARK: - Private Methods

    private func perform(
        _ networkRequest: NetworkRequest,
        body: Data?
    ) async throws -> Data {
        try Task.checkCancellation()

        var request = try makeURLRequest(
            from: networkRequest,
            body: body
        )
        request.httpBody = body

        var attempt = 1

        while true {
            try Task.checkCancellation()

            let (data, response) = try await send(request)
            try Task.checkCancellation()

            guard Constants.successfulStatusCodes.contains(
                response.statusCode
            ) else {
                guard retryPolicy.shouldRetry(
                    statusCode: response.statusCode,
                    method: networkRequest.method,
                    afterAttempt: attempt
                ) else {
                    let message = NetworkErrorMessageParser.message(from: data)
                    throw NetworkError.httpStatus(
                        code: response.statusCode,
                        message: message
                    )
                }

                let delay = retryPolicy.delay(
                    afterAttempt: attempt
                )
                let delayMilliseconds = Int64(
                    (delay * 1_000).rounded()
                )
                attempt += 1
                try await Task.sleep(
                    for: .milliseconds(delayMilliseconds)
                )
                continue
            }

            return data
        }
    }

    private func send(
        _ request: URLRequest
    ) async throws -> (Data, HTTPURLResponse) {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(
                for: request
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError {
            if error.code == .cancelled,
               Task.isCancelled {
                throw CancellationError()
            }

            throw NetworkError.transport(error)
        } catch {
            throw NetworkError.transport(
                URLError(
                    .unknown,
                    userInfo: [
                        NSUnderlyingErrorKey: error
                    ]
                )
            )
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        return (data, httpResponse)
    }

    private func makeURLRequest(
        from networkRequest: NetworkRequest,
        body: Data?
    ) throws -> URLRequest {
        let path = networkRequest.path.trimmingCharacters(
            in: CharacterSet(charactersIn: "/")
        )
        let endpointURL = path.isEmpty
            ? baseURL
            : baseURL.appending(path: path)

        guard
            var components = URLComponents(
                url: endpointURL,
                resolvingAgainstBaseURL: false
            )
        else {
            throw NetworkError.invalidURL
        }

        if !networkRequest.queryItems.isEmpty {
            components.queryItems = networkRequest.queryItems
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = networkRequest.method.rawValue

        networkRequest.headers.forEach { header, value in
            request.setValue(value, forHTTPHeaderField: header)
        }

        request.setValue(
            Constants.jsonContentType,
            forHTTPHeaderField: Constants.acceptHeader
        )
        request.setValue(
            Constants.bearerPrefix + token,
            forHTTPHeaderField: Constants.authorizationHeader
        )

        if body != nil {
            request.setValue(
                Constants.jsonContentType,
                forHTTPHeaderField: Constants.contentTypeHeader
            )
        }

        return request
    }

    private func encode<Body>(
        _ body: Body
    ) throws -> Data
    where Body: Encodable & Sendable {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .custom { date, encoder in
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [
                    .withInternetDateTime,
                    .withFractionalSeconds
                ]
                var container = encoder.singleValueContainer()
                try container.encode(formatter.string(from: date))
            }
            return try encoder.encode(body)
        } catch {
            throw NetworkError.requestEncoding(error)
        }
    }

    private func decode<Response>(
        _ type: Response.Type,
        from data: Data
    ) throws -> Response
    where Response: Decodable & Sendable {
        guard !data.isEmpty else {
            throw NetworkError.emptyResponse
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let value = try container.decode(String.self)
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [
                    .withInternetDateTime,
                    .withFractionalSeconds
                ]
                let fallbackFormatter = ISO8601DateFormatter()
                fallbackFormatter.formatOptions = [.withInternetDateTime]

                guard let date = formatter.date(from: value)
                        ?? fallbackFormatter.date(from: value) else {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Некорректная дата: \(value)"
                    )
                }

                return date
            }
            return try decoder.decode(type, from: data)
        } catch {
            throw NetworkError.responseDecoding(error)
        }
    }

}
