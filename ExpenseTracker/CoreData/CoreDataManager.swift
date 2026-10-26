// CoreDataManager.swift
// ExpenseTracker
//
// Singleton that owns the NSPersistentContainer.
// The NSManagedObjectModel is built PROGRAMMATICALLY in code —
// no .xcdatamodeld binary file is required.
//
// Interview talking point:
//   This demonstrates that .xcdatamodeld is just a visual editor for
//   what ultimately becomes an NSManagedObjectModel at runtime.
//   Building it in code gives you full control and makes the stack
//   visible/testable without Xcode-generated files.

import CoreData
import Foundation

// MARK: - CoreDataManager

final class CoreDataManager {

    // MARK: - Singleton
    static let shared = CoreDataManager()

    // MARK: - Container
    let container: NSPersistentContainer

    /// Convenience accessor for the main-thread (view) context.
    var context: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Init
    private init() {
        container = NSPersistentContainer(
            name: "ExpenseTracker",
            managedObjectModel: CoreDataManager.makeModel()
        )
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In production: use structured logging / crash reporting.
                fatalError("CoreData store failed to load: \(error), \(error.userInfo)")
            }
        }
        // Merge changes pushed from background contexts into the view context automatically.
        container.viewContext.automaticallyMergesChangesFromParent = true
        // Last-write wins: object properties in memory override the persistent store.
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Save Helper

    /// Saves the view context if it has unsaved changes. Rolls back on failure.
    func save() {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            ctx.rollback()
            print("[CoreDataManager] Save failed — rolled back. Error: \(error)")
        }
    }

    // MARK: - Programmatic NSManagedObjectModel

    /// Constructs the full CoreData schema at runtime using NSEntityDescription
    /// and NSAttributeDescription. Equivalent to what Xcode parses from .xcdatamodeld.
    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // ── ExpenseEntity ────────────────────────────────────────────────────
        let entity = NSEntityDescription()
        entity.name = "ExpenseEntity"
        // NSStringFromClass picks up the @objc name "ExpenseEntity" (without module prefix)
        // so CoreData's NSClassFromString lookup succeeds at runtime.
        entity.managedObjectClassName = NSStringFromClass(ExpenseEntity.self)

        // Helper closure to reduce repetition when defining attributes.
        func makeAttribute(
            name: String,
            type: NSAttributeType,
            isOptional: Bool = false
        ) -> NSAttributeDescription {
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.isOptional = isOptional
            return attr
        }

        entity.properties = [
            makeAttribute(name: "id",       type: .UUIDAttributeType),
            makeAttribute(name: "title",    type: .stringAttributeType),
            makeAttribute(name: "amount",   type: .doubleAttributeType),
            makeAttribute(name: "date",     type: .dateAttributeType),
            makeAttribute(name: "category", type: .stringAttributeType),
            makeAttribute(name: "note",     type: .stringAttributeType, isOptional: true)
        ]

        model.entities = [entity]
        return model
    }
}
