//
//  PasscodeStorage.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 05.08.2026.
//

import Foundation
import Security

private enum Constants {
    static let fallbackService = "SHMR.Finance"
}

struct PasscodeAttemptState: Codable {
    var failedAttempts: Int
    var lockoutUntil: Date?
    var lockoutStartedAtUptime: TimeInterval?
    var lockoutDuration: TimeInterval?

    static let empty = PasscodeAttemptState(
        failedAttempts: .zero,
        lockoutUntil: nil,
        lockoutStartedAtUptime: nil,
        lockoutDuration: nil
    )
}

enum PasscodeStorageError: Error {
    case invalidData
    case unexpectedStatus
}

struct PasscodeStorage {
    private enum Account {
        static let passcode = "appPasscode"
        static let attemptState = "appPasscodeAttemptState"
    }

    private let service: String

    init(
        service: String = Bundle.main.bundleIdentifier
            ?? Constants.fallbackService
    ) {
        self.service = service
    }

    func loadPasscode() throws -> String? {
        guard let data = try readData(for: Account.passcode) else {
            return nil
        }

        guard let passcode = String(data: data, encoding: .utf8) else {
            throw PasscodeStorageError.invalidData
        }

        return passcode
    }

    func savePasscode(_ passcode: String) throws {
        try writeData(
            Data(passcode.utf8),
            for: Account.passcode
        )
    }

    func loadAttemptState() throws -> PasscodeAttemptState {
        guard let data = try readData(for: Account.attemptState) else {
            return .empty
        }

        do {
            return try JSONDecoder().decode(
                PasscodeAttemptState.self,
                from: data
            )
        } catch {
            throw PasscodeStorageError.invalidData
        }
    }

    func saveAttemptState(
        _ attemptState: PasscodeAttemptState
    ) throws {
        let data: Data

        do {
            data = try JSONEncoder().encode(attemptState)
        } catch {
            throw PasscodeStorageError.invalidData
        }

        try writeData(data, for: Account.attemptState)
    }

    func removeAllData() throws {
        try deleteData(for: Account.passcode)
        try deleteData(for: Account.attemptState)
    }

    private func readData(for account: String) throws -> Data? {
        var result: CFTypeRef?
        var query = baseQuery(for: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw PasscodeStorageError.invalidData
            }
            return data

        case errSecItemNotFound:
            return nil

        default:
            throw PasscodeStorageError.unexpectedStatus
        }
    }

    private func writeData(
        _ data: Data,
        for account: String
    ) throws {
        let query = baseQuery(for: account)
        let update = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            update as CFDictionary
        )

        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw PasscodeStorageError.unexpectedStatus
        }

        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] =
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let addStatus = SecItemAdd(
            item as CFDictionary,
            nil
        )

        guard addStatus == errSecSuccess else {
            throw PasscodeStorageError.unexpectedStatus
        }
    }

    private func deleteData(for account: String) throws {
        let status = SecItemDelete(
            baseQuery(for: account) as CFDictionary
        )

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw PasscodeStorageError.unexpectedStatus
        }
    }

    private func baseQuery(for account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
