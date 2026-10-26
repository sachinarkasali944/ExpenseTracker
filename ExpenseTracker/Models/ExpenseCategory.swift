// ExpenseCategory.swift
// ExpenseTracker
//
// Enum representing all supported expense categories.
//
// Conforms to String so it can be stored directly in CoreData
// as a String attribute — no custom transformer needed.
// CaseIterable enables ForEach/Picker iteration.
// Identifiable allows use in SwiftUI List/ForEach without explicit id:.

import SwiftUI

// MARK: - ExpenseCategory

enum ExpenseCategory: String, CaseIterable, Identifiable {
    case food          = "Food"
    case transport     = "Transport"
    case entertainment = "Entertainment"
    case health        = "Health"
    case shopping      = "Shopping"
    case utilities     = "Utilities"
    case other         = "Other"

    // MARK: Identifiable
    var id: String { rawValue }

    // MARK: Display
    var displayName: String { rawValue }

    // MARK: SF Symbol
    var systemImage: String {
        switch self {
        case .food:          return "fork.knife"
        case .transport:     return "car.fill"
        case .entertainment: return "gamecontroller.fill"
        case .health:        return "heart.fill"
        case .shopping:      return "bag.fill"
        case .utilities:     return "bolt.fill"
        case .other:         return "ellipsis.circle.fill"
        }
    }

    // MARK: Color (HSL-tuned, harmonious palette)
    var color: Color {
        switch self {
        case .food:          return Color(hue: 0.08, saturation: 0.80, brightness: 0.82)  // warm orange
        case .transport:     return Color(hue: 0.58, saturation: 0.75, brightness: 0.85)  // sky blue
        case .entertainment: return Color(hue: 0.76, saturation: 0.68, brightness: 0.85)  // soft purple
        case .health:        return Color(hue: 0.35, saturation: 0.70, brightness: 0.72)  // green
        case .shopping:      return Color(hue: 0.94, saturation: 0.70, brightness: 0.85)  // rose pink
        case .utilities:     return Color(hue: 0.13, saturation: 0.75, brightness: 0.85)  // amber
        case .other:         return Color(hue: 0.55, saturation: 0.45, brightness: 0.65)  // slate
        }
    }
}
