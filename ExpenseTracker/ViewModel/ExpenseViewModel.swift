// ExpenseViewModel.swift
// ExpenseTracker
//
// The single ViewModel for the app.
//
// Design decisions:
//   • @MainActor — guarantees all @Published mutations happen on the main thread,
//     which is required because NSManagedObjectContext (view context) is not
//     thread-safe and SwiftUI observes changes on the main thread.
//   • Depends on ExpenseRepository protocol (not the concrete impl) —
//     allows clean unit testing via mock injection.
//   • Filtering (search, category) is done as computed properties over
//     `expenses`, NOT as additional CoreData fetches — keeps the source of
//     truth in one place and avoids stale-fetch bugs.

import Foundation
import Combine

// MARK: - ExpenseViewModel

@MainActor
final class ExpenseViewModel: ObservableObject {

    // MARK: - Published State
    @Published var expenses: [Expense] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: ExpenseCategory? = nil
    @Published var errorMessage: String? = nil

    // MARK: - Dependencies
    private let repository: ExpenseRepository

    // MARK: - Init
    init(repository: ExpenseRepository = ExpenseRepositoryImpl()) {
        self.repository = repository
        loadExpenses()
    }

    // MARK: - Computed: Filtered Expenses
    /// Applied in order: category filter first (faster), then search text.
    var filteredExpenses: [Expense] {
        var result = expenses

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query)
                || $0.category.displayName.lowercased().contains(query)
                || $0.note.lowercased().contains(query)
            }
        }

        return result
    }

    // MARK: - Computed: Monthly Totals

    /// Total of ALL expenses in the current calendar month.
    var currentMonthTotal: Double {
        let calendar = Calendar.current
        let now = Date()
        return expenses
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    /// Total of FILTERED expenses (category + search) in the current calendar month.
    var filteredMonthlyTotal: Double {
        let calendar = Calendar.current
        let now = Date()
        return filteredExpenses
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: - CRUD Operations

    func loadExpenses() {
        do {
            expenses = try repository.fetchAll()
        } catch {
            errorMessage = "Failed to load expenses: \(error.localizedDescription)"
        }
    }

    func addExpense(_ expense: Expense) {
        do {
            try repository.add(expense)
            loadExpenses()
        } catch {
            errorMessage = "Failed to add expense: \(error.localizedDescription)"
        }
    }

    func updateExpense(_ expense: Expense) {
        do {
            try repository.update(expense)
            loadExpenses()
        } catch {
            errorMessage = "Failed to update expense: \(error.localizedDescription)"
        }
    }

    func deleteExpense(_ expense: Expense) {
        do {
            try repository.delete(expense)
            loadExpenses()
        } catch {
            errorMessage = "Failed to delete expense: \(error.localizedDescription)"
        }
    }

    /// Called by SwiftUI's .onDelete modifier with IndexSet relative to filteredExpenses.
    func deleteExpenses(at offsets: IndexSet) {
        let toDelete = offsets.map { filteredExpenses[$0] }
        toDelete.forEach { deleteExpense($0) }
    }

    // MARK: - Per-Category Total (for analytics / charts extension)
    func total(for category: ExpenseCategory) -> Double {
        expenses
            .filter { $0.category == category }
            .reduce(0) { $0 + $1.amount }
    }
}
