// AddEditExpenseView.swift
// ExpenseTracker
//
// A single Form used for BOTH adding a new expense AND editing an existing one.
//
// Design:
//   • `expenseToEdit: Expense?` distinguishes the two modes.
//     nil  → Add mode (blank form, title "New Expense")
//     non-nil → Edit mode (pre-populated form, title "Edit Expense")
//   • All @State fields are private and seeded from expenseToEdit in init.
//   • The ViewModel is passed in (not @StateObject) so the caller's instance
//     is updated — both the list and the form stay in sync.

import SwiftUI

// MARK: - AddEditExpenseView

struct AddEditExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ExpenseViewModel

    let expenseToEdit: Expense?

    // MARK: - Form State
    @State private var title: String
    @State private var amountText: String
    @State private var date: Date
    @State private var category: ExpenseCategory
    @State private var note: String

    @State private var showValidationAlert = false

    // MARK: - Computed
    private var isEditing: Bool { expenseToEdit != nil }

    // MARK: - Init
    init(viewModel: ExpenseViewModel, expenseToEdit: Expense? = nil) {
        self.viewModel      = viewModel
        self.expenseToEdit  = expenseToEdit

        if let e = expenseToEdit {
            // Edit mode: pre-populate all fields from the existing expense.
            _title      = State(initialValue: e.title)
            _amountText = State(initialValue: String(format: "%.2f", e.amount))
            _date       = State(initialValue: e.date)
            _category   = State(initialValue: e.category)
            _note       = State(initialValue: e.note)
        } else {
            // Add mode: blank defaults.
            _title      = State(initialValue: "")
            _amountText = State(initialValue: "")
            _date       = State(initialValue: .now)
            _category   = State(initialValue: .other)
            _note       = State(initialValue: "")
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                // ── Details ──────────────────────────────────────────────────
                Section("Expense Details") {
                    TextField("Title  (e.g. Lunch)", text: $title)
                        .submitLabel(.next)

                    HStack {
                        Text(Locale.current.currencySymbol ?? "$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                // ── Category ─────────────────────────────────────────────────
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.systemImage)
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(category.color)

                    // Live preview of the chosen category badge
                    HStack {
                        Image(systemName: category.systemImage)
                            .foregroundStyle(category.color)
                        Text(category.displayName)
                            .foregroundStyle(category.color)
                            .fontWeight(.medium)
                        Spacer()
                        Circle()
                            .fill(category.color.opacity(0.15))
                            .frame(width: 10, height: 10)
                    }
                    .animation(.easeInOut(duration: 0.2), value: category)
                }

                // ── Note ─────────────────────────────────────────────────────
                Section("Note (Optional)") {
                    TextField("Add a note...", text: $note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle(isEditing ? "Edit Expense" : "New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Add") {
                        saveExpense()
                    }
                    .fontWeight(.semibold)
                    .tint(category.color)
                }
            }
            .alert("Invalid Input", isPresented: $showValidationAlert) {
                Button("OK") {}
            } message: {
                Text("Please enter a title and an amount greater than zero.")
            }
        }
    }

    // MARK: - Save
    private func saveExpense() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !trimmedTitle.isEmpty,
            let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")),
            amount > 0
        else {
            showValidationAlert = true
            return
        }

        if isEditing, var updated = expenseToEdit {
            // Mutate a copy of the domain struct, then ask ViewModel to persist.
            updated.title    = trimmedTitle
            updated.amount   = amount
            updated.date     = date
            updated.category = category
            updated.note     = note.trimmingCharacters(in: .whitespacesAndNewlines)
            viewModel.updateExpense(updated)
        } else {
            let expense = Expense(
                title:    trimmedTitle,
                amount:   amount,
                date:     date,
                category: category,
                note:     note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            viewModel.addExpense(expense)
        }
        dismiss()
    }
}

// MARK: - Preview
#Preview("Add Mode") {
    AddEditExpenseView(viewModel: ExpenseViewModel())
}
