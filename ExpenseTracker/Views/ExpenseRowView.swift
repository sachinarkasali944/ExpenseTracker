// ExpenseRowView.swift
// ExpenseTracker
//
// A single row in the expense list.
// Shows: category icon (coloured circle), title, date, optional note, and amount.

import SwiftUI

// MARK: - ExpenseRowView

struct ExpenseRowView: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 14) {

            // ── Category Icon ────────────────────────────────────────────────
            ZStack {
                Circle()
                    .fill(expense.category.color.opacity(0.14))
                    .frame(width: 48, height: 48)
                Image(systemName: expense.category.systemImage)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(expense.category.color)
            }

            // ── Text Content ─────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(expense.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !expense.note.isEmpty {
                    Text(expense.note)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // ── Amount ───────────────────────────────────────────────────────
            Text(expense.formattedAmount)
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(expense.category.color)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Preview
#Preview {
    List {
        ExpenseRowView(expense: Expense(title: "Lunch at café", amount: 18.50, date: .now, category: .food, note: "With team"))
        ExpenseRowView(expense: Expense(title: "Monthly gym", amount: 55.00, date: .now, category: .health, note: ""))
        ExpenseRowView(expense: Expense(title: "Netflix", amount: 15.99, date: .now, category: .entertainment, note: "Shared plan"))
    }
    .listStyle(.plain)
}
