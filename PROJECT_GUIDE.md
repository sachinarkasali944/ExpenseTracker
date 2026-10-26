# 💰 Expense Tracker — iOS App

> **Interview-Ready iOS Project** | SwiftUI · CoreData · MVVM · Repository Pattern

---

## 📱 Features

| Feature | Description |
|---|---|
| ➕ **Add Expense** | Form with title, amount, date, category, and optional note |
| ✏️ **Edit Expense** | Tap any row or swipe-right to edit in the same shared form |
| 🗑️ **Delete Expense** | Swipe-left to delete with full-swipe support |
| 🏷️ **Categories** | 7 categories, each with unique SF Symbol + HSL colour |
| 🔍 **Search** | Live search across title, category and note fields |
| 📅 **Monthly Total** | Gradient summary card showing current-month spending |
| 🎛️ **Filter by Category** | Horizontal scrolling category chips, toggle on/off |
| 💾 **Local Persistence** | CoreData — survives app kills and reboots |

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────┐
│                    Views                     │  SwiftUI – reads ViewModel only
│  ExpenseListView · AddEditExpenseView · …    │
└────────────────────┬─────────────────────────┘
                     │ @StateObject / @ObservedObject
┌────────────────────▼─────────────────────────┐
│              ExpenseViewModel                │  @MainActor ObservableObject
│  filteredExpenses · monthlyTotal · CRUD …    │
└────────────────────┬─────────────────────────┘
                     │ protocol ExpenseRepository
┌────────────────────▼─────────────────────────┐
│           ExpenseRepositoryImpl              │  Concrete CoreData implementation
│  NSFetchRequest · NSPredicate · NSSortDesc…  │
└────────────────────┬─────────────────────────┘
                     │
┌────────────────────▼─────────────────────────┐
│             CoreDataManager                  │  NSPersistentContainer singleton
│  makeModel() · save() · viewContext          │  (programmatic model — no .xcdatamodeld)
└──────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
ExpenseTracker/
├── CoreData/
│   ├── CoreDataManager.swift       # Programmatic NSManagedObjectModel + container
│   └── ExpenseEntity.swift         # NSManagedObject subclass (@NSManaged properties)
│
├── Models/
│   ├── ExpenseCategory.swift       # Enum: rawValue=String, CaseIterable, SF Symbol + Color
│   └── Expense.swift               # Domain struct (decoupled from CoreData)
│
├── Repository/
│   ├── ExpenseRepository.swift     # Protocol: fetchAll / add / update / delete
│   └── ExpenseRepositoryImpl.swift # CoreData implementation (NSFetchRequest + NSPredicate)
│
├── ViewModel/
│   └── ExpenseViewModel.swift      # @MainActor ObservableObject; filtered + totals
│
├── Views/
│   ├── ExpenseListView.swift        # Root list: search + filter + swipe actions
│   ├── ExpenseRowView.swift         # Individual row cell
│   ├── AddEditExpenseView.swift     # Shared Add/Edit form
│   ├── CategoryFilterView.swift     # Horizontal chip bar
│   └── MonthlyTotalView.swift       # Gradient summary card
│
├── ExpenseTrackerApp.swift          # @main — eager CoreData init
└── ContentView.swift                # Thin root host
```

---

## 🔑 Key Concepts Covered

### CoreData Stack (Programmatic)

```swift
// No .xcdatamodeld file needed — built entirely in code:
private static func makeModel() -> NSManagedObjectModel {
    let model = NSManagedObjectModel()
    let entity = NSEntityDescription()
    entity.name = "ExpenseEntity"
    entity.managedObjectClassName = NSStringFromClass(ExpenseEntity.self)
    entity.properties = [ /* NSAttributeDescription per field */ ]
    model.entities = [entity]
    return model
}
```

### Domain Model Separation

```swift
// ✅ Views and ViewModel work with this clean struct:
struct Expense: Identifiable, Equatable { ... }

// ✅ NSManagedObject is ONLY seen inside the Repository:
@objc(ExpenseEntity)
class ExpenseEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var amount: Double
    // ...
}
```

### Repository Pattern

```swift
protocol ExpenseRepository {
    func fetchAll() throws -> [Expense]
    func add(_ expense: Expense) throws
    func update(_ expense: Expense) throws
    func delete(_ expense: Expense) throws
}
```
> Swap CoreData for SwiftData or a REST API by writing a new conformer — **zero ViewModel changes**.

### @MainActor ViewModel

```swift
@MainActor
final class ExpenseViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: ExpenseCategory? = nil

    var filteredExpenses: [Expense] { /* computed, no extra fetch */ }
    var currentMonthTotal: Double   { /* computed over expenses */ }
}
```

---

## 🚀 Setup

1. Open `ExpenseTracker.xcodeproj` in Xcode 15+.
2. Select your target device / simulator.
3. **Build & Run** (`⌘R`) — no extra dependencies, no CocoaPods, no SPM packages.
4. The CoreData store is created automatically in the device's Application Support directory.

> **Minimum deployment target**: iOS 17 (uses `@Previewable`, `.contentTransition(.numericText())`, `.symbolEffect`)

---

## 🧪 Testing Strategy

| Test Type | What to test |
|---|---|
| **Unit** | Inject `MockExpenseRepository` into `ExpenseViewModel`; assert `filteredExpenses` and `currentMonthTotal` |
| **Integration** | Use `NSPersistentContainer` with `inMemory: true` store for CRUD round-trips |
| **UI** | Tap "+ button" → form appears; fill fields → dismiss → row in list |

---

## 📐 Data Model

| Attribute | Type | CoreData Type | Notes |
|---|---|---|---|
| `id` | UUID | UUIDAttributeType | Primary key |
| `title` | String | stringAttributeType | Required |
| `amount` | Double | doubleAttributeType | Required, > 0 |
| `date` | Date | dateAttributeType | Required |
| `category` | String | stringAttributeType | `ExpenseCategory.rawValue` |
| `note` | String? | stringAttributeType | Optional |

---

## 👨‍💻 Author

Built as an interview-ready practice project — demonstrating CoreData, MVVM, and Repository patterns in a real SwiftUI app.
