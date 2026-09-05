//
//  FinanceCoreDataModel.swift
//  SHMR Finance
//
//  Created by Andrei Kovryzhenko on 26.07.2026.
//

@preconcurrency import CoreData
import Foundation

nonisolated enum FinanceCoreDataModel {
    static let name = "FinanceCoreData"

    static func make() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        model.entities = [
            transactionEntity(),
            accountEntity(),
            categoryEntity(),
            pendingTransactionEntity(),
            pendingAccountEntity()
        ]
        return model
    }

    private static func transactionEntity() -> NSEntityDescription {
        let accountId = attribute("accountId", .integer64AttributeType)
        accountId.defaultValue = Int64.zero

        let transaction = entity(
            name: CoreDataStoredTransaction.entityName,
            className: CoreDataStoredTransaction.self,
            attributes: [
                attribute("transactionId", .integer64AttributeType),
                accountId,
                attribute("payload", .binaryDataAttributeType),
                attribute("transactionDate", .dateAttributeType)
            ],
            uniquenessConstraints: [["transactionId"]]
        )
        transaction.indexes = [
            NSFetchIndexDescription(
                name: "StoredTransactionByAccount",
                elements: [
                    NSFetchIndexElementDescription(
                        property: accountId,
                        collationType: .binary
                    )
                ]
            )
        ]
        return transaction
    }

    private static func accountEntity() -> NSEntityDescription {
        entity(
            name: CoreDataStoredAccount.entityName,
            className: CoreDataStoredAccount.self,
            attributes: [
                attribute("accountId", .integer64AttributeType),
                attribute("payload", .binaryDataAttributeType)
            ],
            uniquenessConstraints: [["accountId"]]
        )
    }

    private static func categoryEntity() -> NSEntityDescription {
        entity(
            name: CoreDataStoredCategory.entityName,
            className: CoreDataStoredCategory.self,
            attributes: [
                attribute("categoryId", .integer64AttributeType),
                attribute("payload", .binaryDataAttributeType)
            ],
            uniquenessConstraints: [["categoryId"]]
        )
    }

    private static func pendingTransactionEntity() -> NSEntityDescription {
        entity(
            name: CoreDataPendingTransaction.entityName,
            className: CoreDataPendingTransaction.self,
            attributes: [
                attribute("transactionId", .integer64AttributeType),
                attribute("actionRawValue", .stringAttributeType),
                attribute("payload", .binaryDataAttributeType, optional: true),
                attribute("balanceAdjustmentPayload", .binaryDataAttributeType),
                attribute("insertedAt", .dateAttributeType),
                attribute("revision", .UUIDAttributeType),
                attribute("stateRawValue", .stringAttributeType),
                attribute("failureMessage", .stringAttributeType, optional: true)
            ],
            uniquenessConstraints: [["transactionId"]]
        )
    }

    private static func pendingAccountEntity() -> NSEntityDescription {
        entity(
            name: CoreDataPendingAccount.entityName,
            className: CoreDataPendingAccount.self,
            attributes: [
                attribute("accountId", .integer64AttributeType),
                attribute("payload", .binaryDataAttributeType),
                attribute("insertedAt", .dateAttributeType),
                attribute("revision", .UUIDAttributeType),
                attribute("stateRawValue", .stringAttributeType),
                attribute("failureMessage", .stringAttributeType, optional: true)
            ],
            uniquenessConstraints: [["accountId"]]
        )
    }

    private static func entity(
        name: String,
        className: AnyClass,
        attributes: [NSAttributeDescription],
        uniquenessConstraints: [[String]]
    ) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = name
        entity.managedObjectClassName = NSStringFromClass(className)
        entity.properties = attributes
        entity.uniquenessConstraints = uniquenessConstraints
        return entity
    }

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool = false
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }
}
