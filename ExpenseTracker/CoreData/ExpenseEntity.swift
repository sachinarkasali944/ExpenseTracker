// ExpenseEntity.swift
// ExpenseTracker
//
// NSManagedObject subclass for the CoreData "ExpenseEntity" entity.
//
// Key concepts:
//   @NSManaged    — tells the Swift compiler that CoreData will provide
//                   the getter/setter at runtime via Key-Value Coding (KVC).
//                   Without it, Swift would generate normal stored properties
//                   that bypass CoreData's change tracking.
//
//   @objc(ExpenseEntity) — registers this class in the Objective-C runtime
//                   under the name "ExpenseEntity" (without module prefix).
//                   CoreDataManager uses NSStringFromClass(ExpenseEntity.self)
//                   to get this name and assign it to entity.managedObjectClassName,
//                   allowing NSPersistentContainer to find the class at load time.

import CoreData
import Foundation

// MARK: - ExpenseEntity

@objc(ExpenseEntity)
class ExpenseEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var amount: Double
    @NSManaged var date: Date
    @NSManaged var category: String  // stores ExpenseCategory.rawValue
    @NSManaged var note: String?
}

// MARK: - Fetch Request Factory

extension ExpenseEntity {
    /// Type-safe NSFetchRequest factory — preferred over string-based initializers.
    @nonobjc static func fetchRequest() -> NSFetchRequest<ExpenseEntity> {
        NSFetchRequest<ExpenseEntity>(entityName: "ExpenseEntity")
    }
}
