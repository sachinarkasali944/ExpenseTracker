// CategoryFilterView.swift
// ExpenseTracker
//
// A horizontally-scrolling row of category filter chips.
// Tapping a chip toggles that category filter on/off.
// Tapping the "All" chip clears the filter.

import SwiftUI

// MARK: - CategoryFilterView

struct CategoryFilterView: View {
    @Binding var selectedCategory: ExpenseCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // "All" chip — clears the category filter
                CategoryChip(
                    label: "All",
                    icon: "square.grid.2x2.fill",
                    color: .secondary,
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )

                // One chip per category
                ForEach(ExpenseCategory.allCases) { category in
                    CategoryChip(
                        label: category.displayName,
                        icon: category.systemImage,
                        color: category.color,
                        isSelected: selectedCategory == category,
                        action: {
                            // Tapping the active chip deselects it (toggle behaviour)
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - CategoryChip

/// A single pill-shaped filter chip.
private struct CategoryChip: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.88) : color.opacity(0.10))
                    .animation(.easeInOut(duration: 0.18), value: isSelected)
            )
            .foregroundColor(isSelected ? .white : color)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var selected: ExpenseCategory? = .food
    CategoryFilterView(selectedCategory: $selected)
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
}
