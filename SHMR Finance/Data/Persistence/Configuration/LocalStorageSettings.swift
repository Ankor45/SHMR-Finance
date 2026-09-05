//
//  LocalStorageSettings.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

import Foundation

actor LocalStorageSettings {
    private static let selectedStorageKey = "localStorageKind"

    private static let activeStorageKey = "activeLocalStorageKind"
    private static let pendingCleanupStorageKey =
        "pendingCleanupLocalStorageKind"
    private let defaults: UserDefaults
    private let activeStorageKey: String
    private let pendingCleanupStorageKey: String

    init(
        defaults: UserDefaults = .standard,
        scope: LocalStorageScope = .live
    ) {
        self.defaults = defaults
        activeStorageKey = scope.settingsKey(Self.activeStorageKey)
        pendingCleanupStorageKey = scope.settingsKey(
            Self.pendingCleanupStorageKey
        )
        defaults.register(defaults: [
            Self.selectedStorageKey: LocalStorageKind.swiftData.rawValue
        ])
    }

    var selectedStorage: LocalStorageKind {
        guard let value = defaults.string(
            forKey: Self.selectedStorageKey
        ) else {
            return .swiftData
        }
        return LocalStorageKind(rawValue: value) ?? .swiftData
    }

    var activeStorage: LocalStorageKind {
        guard let value = defaults.string(
            forKey: activeStorageKey
        ) else {
            // SwiftData was the only implementation before this setting existed.
            return .swiftData
        }
        return LocalStorageKind(rawValue: value) ?? .swiftData
    }

    var pendingCleanupStorage: LocalStorageKind? {
        guard let value = defaults.string(
            forKey: pendingCleanupStorageKey
        ) else {
            return nil
        }
        return LocalStorageKind(rawValue: value)
    }

    func activate(
        _ storage: LocalStorageKind,
        previousStorage: LocalStorageKind
    ) {
        defaults.set(
            previousStorage.rawValue,
            forKey: pendingCleanupStorageKey
        )
        defaults.set(storage.rawValue, forKey: activeStorageKey)
    }

    func finishCleanup() {
        defaults.removeObject(forKey: pendingCleanupStorageKey)
    }
}
