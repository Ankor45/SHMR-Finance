//
//  LocalStorageScope.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 04.09.2026.
//

private nonisolated enum Constants {
    static let liveSwiftDataStoreFileName = "finance.store"
    static let demoSwiftDataStoreFileName = "finance-demo.store"
    static let liveCoreDataStoreFileName = "finance-coredata.sqlite"
    static let demoCoreDataStoreFileName = "finance-demo-coredata.sqlite"
    static let settingsKeySeparator = "."
}

nonisolated enum LocalStorageScope: String, Sendable {
    case live
    case demo

    var swiftDataStoreFileName: String {
        switch self {
        case .live:
            Constants.liveSwiftDataStoreFileName
        case .demo:
            Constants.demoSwiftDataStoreFileName
        }
    }

    var coreDataStoreFileName: String {
        switch self {
        case .live:
            Constants.liveCoreDataStoreFileName
        case .demo:
            Constants.demoCoreDataStoreFileName
        }
    }

    func settingsKey(_ baseKey: String) -> String {
        switch self {
        case .live:
            baseKey
        case .demo:
            "\(baseKey)\(Constants.settingsKeySeparator)\(rawValue)"
        }
    }
}
