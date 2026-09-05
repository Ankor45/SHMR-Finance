//
//  LocalStorageFactory.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

nonisolated struct LocalStorageFactory: Sendable {
    private let scope: LocalStorageScope

    init(scope: LocalStorageScope = .live) {
        self.scope = scope
    }

    func makeStorage(
        for kind: LocalStorageKind
    ) throws -> any FinanceLocalStorage {
        switch kind {
        case .swiftData:
            try SwiftDataFinanceStorage(
                storeFileName: scope.swiftDataStoreFileName
            )
        case .coreData:
            try CoreDataFinanceStorage(
                storeFileName: scope.coreDataStoreFileName
            )
        }
    }
}
