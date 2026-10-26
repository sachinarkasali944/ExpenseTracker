// ExpenseRepository.swift
// ExpenseTracker
//
// Protocol that abstracts all persistence operations for `Expense`.
//
// Why a protocol?
//   • The ViewModel depends on this abstraction, NOT on CoreData directly.
//   • A MockExpenseRepository can be injected during unit tests,
//     letting you test all ViewModel logic without touching the disk.
//   • Swapping persistence backends (CoreData → SwiftData → REST API)
//     only requires a new conforming type — zero ViewModel changes.

import Foundation

// MARK: - ExpenseRepository

protocol ExpenseRepository {
    /// Fetches all expenses, sorted by date descending.
    func fetchAll() throws -> [Expense]

    /// Inserts a new expense into the store.
    func add(_ expense: Expense) throws

    /// Updates an existing expense matched by `expense.id`.
    func update(_ expense: Expense) throws

    /// Deletes the expense matched by `expense.id`.
    func delete(_ expense: Expense) throws
}
