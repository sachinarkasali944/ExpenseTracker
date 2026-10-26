// MonthlyTotalView.swift
// ExpenseTracker
//
// A summary card that displays the current month's expense total.
// Shows the full month total on the left, and a category-filtered
// breakdown on the right when a category is active.

import SwiftUI

// MARK: - MonthlyTotalView

struct MonthlyTotalView: View {
    let total: Double
    let filteredTotal: Double
    let selectedCategory: ExpenseCategory?

    // MARK: - Body
    var body: some View {
        ZStack {
            // Card background: deep indigo → violet gradient
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(hue: 0.64, saturation: 0.80, brightness: 0.40), location: 0),
                            .init(color: Color(hue: 0.74, saturation: 0.82, brightness: 0.30), location: 1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.30), radius: 12, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 14) {
                // Top row: label + month
                HStack {
                    Label("Monthly Spending", systemImage: "chart.bar.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.75))
                    Spacer()
                    Text(currentMonthLabel)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.60))
                }

                // Bottom row: total + optional category breakdown
                HStack(alignment: .bottom) {
                    // Full month total
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.55))
                        Text(formatted(total))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .animation(.spring(duration: 0.4), value: total)
                    }

                    Spacer()

                    // Category breakdown badge (shown when filter is active)
                    if let category = selectedCategory {
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 5) {
                                Image(systemName: category.systemImage)
                                    .font(.caption2)
                                Text(category.displayName)
                                    .font(.caption2)
                            }
                            .foregroundColor(category.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(category.color.opacity(0.18)))

                            Text(formatted(filteredTotal))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(category.color)
                                .contentTransition(.numericText())
                                .animation(.spring(duration: 0.4), value: filteredTotal)
                        }
                    }
                }
            }
            .padding(20)
        }
        .padding(.horizontal)
        .frame(height: 120)
    }

    // MARK: - Helpers
    private var currentMonthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: .now)
    }

    private func formatted(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        return f.string(from: NSNumber(value: amount)) ?? "—"
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        MonthlyTotalView(total: 4250.75, filteredTotal: 1200.00, selectedCategory: .food)
        MonthlyTotalView(total: 4250.75, filteredTotal: 4250.75, selectedCategory: nil)
    }
    .padding(.vertical)
    .background(Color(.systemGroupedBackground))
}
