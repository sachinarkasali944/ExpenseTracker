// ExpenseListView.swift
// ExpenseTracker
//
// Main screen of the app.
// Composes: MonthlyTotalView, CategoryFilterView, and the expense List.
//
// Features:
//   • .searchable — SwiftUI provides the search bar; the ViewModel filters reactively.
//   • Swipe-left (trailing) to Delete.
//   • Swipe-right (leading) to Edit.
//   • Tap row to Edit.
//   • Toolbar + button to Add.

import SwiftUI

// MARK: - ExpenseListView

struct ExpenseListView: View {
    @StateObject private var viewModel = ExpenseViewModel()

    @State private var showingAddSheet  = false
    @State private var expenseToEdit: Expense? = nil

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── Monthly Summary Card ──────────────────────────────────────
                MonthlyTotalView(
                    total:             viewModel.currentMonthTotal,
                    filteredTotal:     viewModel.filteredMonthlyTotal,
                    selectedCategory:  viewModel.selectedCategory
                )
                .padding(.top, 8)

                // ── Category Filter Chips ─────────────────────────────────────
                CategoryFilterView(selectedCategory: $viewModel.selectedCategory)

                Divider()

                // ── Expense List / Empty State ────────────────────────────────
                if viewModel.filteredExpenses.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(viewModel.filteredExpenses) { expense in
                            ExpenseRowView(expense: expense)
                                .contentShape(Rectangle())
                                .onTapGesture { expenseToEdit = expense }
                                // Swipe LEFT → Delete
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation { viewModel.deleteExpense(expense) }
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                }
                                // Swipe RIGHT → Edit
                                .swipeActions(edge: .leading) {
                                    Button {
                                        expenseToEdit = expense
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.indigo)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .animation(.default, value: viewModel.filteredExpenses.map(\.id))
                }
            }
            // ── Navigation ────────────────────────────────────────────────────
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.large)
            // SwiftUI's native search bar — binding drives ViewModel filter.
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search by title, category or note…"
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolEffect(.bounce, value: showingAddSheet)
                    }
                }
            }
            // ── Sheets ────────────────────────────────────────────────────────
            .sheet(isPresented: $showingAddSheet) {
                AddEditExpenseView(viewModel: viewModel)
            }
            .sheet(item: $expenseToEdit) { expense in
                AddEditExpenseView(viewModel: viewModel, expenseToEdit: expense)
            }
            // ── Error Banner ──────────────────────────────────────────────────
            .alert("Something went wrong", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("Dismiss") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "tray.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary.opacity(0.35))
                .symbolEffect(.pulse)

            Text("No Expenses Found")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text(
                viewModel.searchText.isEmpty
                ? "Tap \(Image(systemName: "plus.circle.fill")) to log your first expense."
                : "No results for \"\(viewModel.searchText)\"."
            )
            .font(.subheadline)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    ExpenseListView()
}
