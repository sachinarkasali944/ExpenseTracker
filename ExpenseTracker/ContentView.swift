//
//  ContentView.swift
//  ExpenseTracker
//
//  Created by Sachin Arkasali on 21/07/26.
//

// ContentView.swift
// ExpenseTracker
//
// Root view — thin host that presents the main Expense List screen.

import SwiftUI

struct ContentView: View {
    var body: some View {
        ExpenseListView()
    }
}

#Preview {
    ContentView()
}
