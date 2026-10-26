// Expense.swift
// ExpenseTracker
//
// Domain model — a plain Swift struct, fully decoupled from CoreData.
//
// Design rationale:
//   The ViewModel and Views work exclusively with `Expense`.
//   NSManagedObject types (ExpenseEntity) are confined to the Repository layer.
//   This means:
//     • Views can never accidentally trigger CoreData context operations.
//     • The ViewModel is fully unit-testable with no CoreData dependency.
//     • Swapping the persistence layer (e.g., SwiftData, SQLite) only
//       requires changes inside the Repository — not in the ViewModel or Views.

import Foundation

// MARK: - Expense

struct Expense: Identifiable, Equatable, Hashable {
    let id: UUID
    var title: String
    var amount: Double
    var date: Date
    var category: ExpenseCategory
    var note: String

    // MARK: - Init from CoreData entity (Repository use only)
    init(entity: ExpenseEntity) {
        self.id       = entity.id
        self.title    = entity.title
        self.amount   = entity.amount
        self.date     = entity.date
        self.category = ExpenseCategory(rawValue: entity.category) ?? .other
        self.note     = entity.note ?? ""
    }

    // MARK: - Memberwise init (ViewModel / test use)
    init(
        id: UUID = UUID(),
        title: String = "",
        amount: Double = 0,
        date: Date = .now,
        category: ExpenseCategory = .other,
        note: String = ""
    ) {
        self.id       = id
        self.title    = title
        self.amount   = amount
        self.date     = date
        self.category = category
        self.note     = note
    }
}

// MARK: - Formatted Helpers

extension Expense {
    /// Currency-formatted amount string using the device locale.
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        return formatter.string(from: NSNumber(value: amount)) ?? "—"
    }

    /// Short date string (e.g., "Jul 21, 2026").
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
