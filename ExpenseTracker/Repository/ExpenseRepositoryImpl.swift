// ExpenseRepositoryImpl.swift
// ExpenseTracker
//
// Concrete CoreData implementation of ExpenseRepository.
//
// Responsibilities:
//   • Translate between the domain model (Expense struct)
//     and the CoreData entity (ExpenseEntity: NSManagedObject).
//   • Execute NSFetchRequests with NSSortDescriptors and NSPredicates.
//   • Delegate all context management to CoreDataManager.
//
// This class is the ONLY place in the app that knows about CoreData.

import CoreData
import Foundation

// MARK: - ExpenseRepositoryImpl

final class ExpenseRepositoryImpl: ExpenseRepository {

    // MARK: - Dependencies
    private let manager: CoreDataManager

    init(manager: CoreDataManager = .shared) {
        self.manager = manager
    }

    // MARK: - Fetch

    /// Returns all expenses sorted by date, newest first.
    func fetchAll() throws -> [Expense] {
        let request = ExpenseEntity.fetchRequest()
        // NSSortDescriptor: ascending = false → newest entries appear at the top.
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ExpenseEntity.date, ascending: false)
        ]
        let entities = try manager.context.fetch(request)
        return entities.map(Expense.init)   // init(entity:) defined in Expense.swift
    }

    // MARK: - Add

    /// Inserts a new ExpenseEntity into the managed object context and saves.
    func add(_ expense: Expense) throws {
        let entity = ExpenseEntity(context: manager.context)
        entity.id       = expense.id
        entity.title    = expense.title
        entity.amount   = expense.amount
        entity.date     = expense.date
        entity.category = expense.category.rawValue
        entity.note     = expense.note.isEmpty ? nil : expense.note
        manager.save()
    }

    // MARK: - Update

    /// Fetches the matching entity by UUID and updates its fields in place.
    ///
    /// Using NSPredicate with UUID comparison is safe because UUID conforms
    /// to CVarArg, bridging correctly to %@ format string substitution.
    func update(_ expense: Expense) throws {
        let request = ExpenseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", expense.id as CVarArg)
        request.fetchLimit = 1  // We only expect one result; limit for efficiency.

        guard let entity = try manager.context.fetch(request).first else {
            print("[ExpenseRepositoryImpl] update: entity not found for id \(expense.id)")
            return
        }
        entity.title    = expense.title
        entity.amount   = expense.amount
        entity.date     = expense.date
        entity.category = expense.category.rawValue
        entity.note     = expense.note.isEmpty ? nil : expense.note
        manager.save()
    }

    // MARK: - Delete

    /// Fetches the matching entity by UUID and deletes it from the context.
    func delete(_ expense: Expense) throws {
        let request = ExpenseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", expense.id as CVarArg)
        request.fetchLimit = 1

        guard let entity = try manager.context.fetch(request).first else {
            print("[ExpenseRepositoryImpl] delete: entity not found for id \(expense.id)")
            return
        }
        manager.context.delete(entity)
        manager.save()
    }
}
