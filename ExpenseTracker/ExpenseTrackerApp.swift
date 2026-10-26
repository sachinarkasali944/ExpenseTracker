//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  Created by Sachin Arkasali on 21/07/26.
//

// ExpenseTrackerApp.swift
// ExpenseTracker
//
// App entry point.
// CoreDataManager.shared is referenced here (eagerly) so the
// NSPersistentContainer is fully loaded before any view appears.

import SwiftUI

@main
struct ExpenseTrackerApp: App {

    // Initialise CoreData stack at launch — not lazily on first use.
    private let coreData = CoreDataManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

