# 📋 Expense Tracker — Interview Questions & Answers

> Covering: **CoreData · MVVM · Repository Pattern · SwiftUI · Swift Internals**

---

## 🗄️ CoreData

---

### Q1. What is NSPersistentContainer and why do we use it?

**A:** `NSPersistentContainer` (introduced in iOS 10) is a convenience class that encapsulates the entire CoreData stack — the managed object model (`NSManagedObjectModel`), the persistent store coordinator (`NSPersistentStoreCoordinator`), and the view context (`NSManagedObjectContext`). Before it existed, developers had to wire these three objects together manually.

```swift
let container = NSPersistentContainer(name: "ExpenseTracker", managedObjectModel: model)
container.loadPersistentStores { _, error in
    if let error { fatalError("Load failed: \(error)") }
}
```

`loadPersistentStores` creates the SQLite database on disk (in Application Support by default) and attaches it to the coordinator.

---

### Q2. What is the role of NSManagedObjectContext? Is it thread-safe?

**A:** `NSManagedObjectContext` (MOC) is the in-memory "scratch pad" where objects are fetched, modified, and tracked for changes. It is **not thread-safe** — you must interact with a context only on the queue it was created on.

- `container.viewContext` → main-queue context → safe for UI reads/writes.
- `container.newBackgroundContext()` → private-queue context → use for heavy imports/batch operations.

The classic mistake is accessing `NSManagedObject` properties on a background thread using the view context. To safely pass data to/from background threads, either pass the `objectID` (thread-safe) or use a separate background context.

---

### Q3. What is @NSManaged and why is it needed?

**A:** `@NSManaged` tells the Swift compiler: *"I won't provide an implementation for this property — CoreData will synthesize it at runtime via Key-Value Coding (KVC)."* Without it, Swift generates a standard stored property that bypasses CoreData's change-tracking mechanism, breaking dirty-tracking and save notifications.

```swift
@objc(ExpenseEntity)
class ExpenseEntity: NSManagedObject {
    @NSManaged var amount: Double  // CoreData synthesises get/set at runtime
}
```

It's semantically similar to `@dynamic` in Objective-C.

---

### Q4. What is NSPredicate and how do you use it safely?

**A:** `NSPredicate` expresses a filter condition for a fetch request. The `%@` format specifier is the safe way to inject values — CoreData (via SQLite) parameterises the query, preventing injection issues.

```swift
// Safe: %@ binds the UUID as a parameter
request.predicate = NSPredicate(format: "id == %@", expense.id as CVarArg)

// String matching (case + diacritic insensitive)
request.predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchText)
// [c] = case-insensitive, [d] = diacritic-insensitive
```

For compile-time safety, prefer KeyPath-based APIs when available.

---

### Q5. What is NSSortDescriptor and how does it affect a fetch?

**A:** `NSSortDescriptor` specifies the sort order of fetched results. It maps directly to an `ORDER BY` clause in the generated SQLite query.

```swift
request.sortDescriptors = [
    NSSortDescriptor(keyPath: \ExpenseEntity.date, ascending: false)
]
```

Using the `keyPath:` variant gives you compile-time safety — typos are caught at build time, not at runtime. You can chain multiple sort descriptors for multi-level sorting.

---

### Q6. How do you build an NSManagedObjectModel programmatically (without .xcdatamodeld)?

**A:** You create `NSEntityDescription` and `NSAttributeDescription` objects in code, assign them to the model, and pass it into `NSPersistentContainer`:

```swift
let model = NSManagedObjectModel()
let entity = NSEntityDescription()
entity.name = "ExpenseEntity"
entity.managedObjectClassName = NSStringFromClass(ExpenseEntity.self)

let idAttr = NSAttributeDescription()
idAttr.name = "id"
idAttr.attributeType = .UUIDAttributeType
idAttr.isOptional = false

entity.properties = [idAttr, /* ... */]
model.entities = [entity]
```

This is what `.xcdatamodeld` compiles down to at runtime — the file is purely a visual editor convenience.

---

### Q7. What is mergePolicy and why did we set NSMergeByPropertyObjectTrumpMergePolicy?

**A:** When two contexts modify the same object concurrently, CoreData detects a **merge conflict** on save. `mergePolicy` determines the resolution strategy:

| Policy | Behaviour |
|---|---|
| `NSErrorMergePolicy` (default) | Throw an error — you handle manually |
| `NSMergeByPropertyStoreTrumpMergePolicy` | Persistent store wins |
| `NSMergeByPropertyObjectTrumpMergePolicy` | In-memory (object) wins |
| `NSOverwriteMergePolicy` | Context completely overwrites the store |

We set `NSMergeByPropertyObjectTrumpMergePolicy` on the view context so that user edits in the UI always win over stale data coming from a background context — suitable for single-user apps.

---

### Q8. How do you perform CoreData operations on a background thread?

**A:** Use `performBackgroundTask` or a background context with `perform`:

```swift
container.performBackgroundTask { backgroundCtx in
    // Safe: backgroundCtx is confined to its private queue
    let entity = ExpenseEntity(context: backgroundCtx)
    entity.title = "Batch import item"
    try? backgroundCtx.save()
}
```

Setting `container.viewContext.automaticallyMergesChangesFromParent = true` means the view context will receive and merge these changes automatically after the background save.

---

### Q9. What is the difference between NSFetchRequest and NSFetchedResultsController?

**A:**
- **`NSFetchRequest`** — a one-shot query. You call `context.fetch(request)` and get an array. Best for simple loads.
- **`NSFetchedResultsController`** — adds a persistent observer that automatically notifies you (via delegate) when the result set changes (inserts, deletes, updates). Built for driving `UITableView` / `UICollectionView` in UIKit. In SwiftUI, `@FetchRequest` provides similar live-updating behaviour.

In this project we use simple `NSFetchRequest` + `loadExpenses()` because SwiftUI's `List` is driven by `@Published expenses` in the ViewModel.

---

### Q10. How would you write a unit test for the Repository?

**A:** Inject an **in-memory** `NSPersistentContainer` so tests run fast and never touch disk:

```swift
func makeInMemoryManager() -> CoreDataManager {
    let desc = NSPersistentStoreDescription()
    desc.type = NSInMemoryStoreType
    // inject into CoreDataManager...
}

func testAddAndFetch() throws {
    let repository = ExpenseRepositoryImpl(manager: makeInMemoryManager())
    let expense = Expense(title: "Coffee", amount: 4.50, category: .food)
    try repository.add(expense)
    let all = try repository.fetchAll()
    XCTAssertEqual(all.count, 1)
    XCTAssertEqual(all.first?.title, "Coffee")
}
```

---

## 🏛️ MVVM & Architecture

---

### Q11. Why is the ViewModel marked @MainActor?

**A:** `@MainActor` is a global actor that guarantees all annotated code runs on the main thread. The ViewModel is marked `@MainActor` for two reasons:

1. **SwiftUI observation** — `@Published` property changes trigger UI updates, which must happen on the main thread.
2. **CoreData view context** — `container.viewContext` is bound to the main queue and must not be accessed from background threads.

Using `@MainActor` is cleaner and safer than manually writing `DispatchQueue.main.async { }` wrappers everywhere.

---

### Q12. Why do Views use @ObservedObject instead of @StateObject for the ViewModel in AddEditExpenseView?

**A:**
- **`@StateObject`** — SwiftUI *owns* the object; it creates it once and keeps it alive for the view's lifetime. Use this in the root view that creates the ViewModel.
- **`@ObservedObject`** — SwiftUI *borrows* an externally-created object. Use this when passing an existing instance down to a child view.

`ExpenseListView` creates the ViewModel with `@StateObject`. `AddEditExpenseView` receives the same instance via `@ObservedObject` — they share state, so changes in the form immediately reflect in the list.

---

### Q13. Why is filtering done as a computed property rather than a separate CoreData fetch?

**A:** Three reasons:

1. **Single source of truth** — `expenses` is the authoritative array. Filtering derives from it; there's no risk of the two going out of sync.
2. **Performance** — for typical personal finance apps (<10,000 rows), in-memory filtering is faster than a round-trip through SQLite.
3. **Reactivity** — because `filteredExpenses` is computed over `@Published expenses` and `@Published searchText`, SwiftUI automatically re-renders whenever either changes.

For very large datasets (100k+ records), you would move filtering into `NSFetchRequest` predicates to leverage SQLite's indexing.

---

### Q14. What is the Repository pattern and what problem does it solve?

**A:** The Repository pattern introduces an abstraction layer between the data source (CoreData, REST API, SQLite) and the business logic (ViewModel). The contract is a protocol:

```swift
protocol ExpenseRepository {
    func fetchAll() throws -> [Expense]
    func add(_ expense: Expense) throws
    // ...
}
```

**Problems it solves:**
- **Testability** — inject a `MockExpenseRepository` in tests; no CoreData setup needed.
- **Replaceability** — switch from CoreData to SwiftData or a remote API by writing one new conforming type.
- **Single Responsibility** — the ViewModel doesn't know how data is stored; the Repository doesn't know how data is displayed.

---

### Q15. What is the difference between SwiftData and CoreData?

**A:**

| Aspect | CoreData | SwiftData |
|---|---|---|
| Introduced | macOS 10.4 / iOS 3 | iOS 17 / macOS 14 |
| Model definition | `.xcdatamodeld` (visual) or programmatic | `@Model` macro on a Swift class |
| Query API | `NSFetchRequest` + `NSPredicate` | `#Predicate`, `@Query` |
| Concurrency | Manual actor/queue management | Swift concurrency native |
| Under the hood | Objective-C runtime + SQLite | CoreData (same stack, new Swift API) |

SwiftData is essentially CoreData with a modern Swift API. CoreData remains important for apps supporting iOS 16 and below or with complex migration needs.

---

### Q16. How does @NSManaged differ from computed properties in an NSManagedObject subclass?

**A:** `@NSManaged` properties are backed by CoreData's KVC mechanism — the framework dynamically generates the getter/setter at runtime and hooks them into dirty-tracking, the undo manager, and the save pipeline.

A **regular computed property** (without `@NSManaged`) is fine for derived, read-only values:

```swift
extension ExpenseEntity {
    // Derived — reads from @NSManaged properties, no storage
    var formattedSummary: String { "\(category): \(amount)" }
}
```

But you must not use a regular stored property for persisted data — CoreData would never know it changed.

---

### Q17. How would you handle CoreData migrations?

**A:** CoreData offers two migration strategies:

1. **Lightweight / Inferred Migration** (most common) — enable `NSMigratePersistentStoresAutomaticallyOption` and `NSInferMappingModelAutomaticallyOption`. CoreData infers the mapping if changes are simple (add/remove attributes, rename entities).

```swift
let options: [AnyHashable: Any] = [
    NSMigratePersistentStoresAutomaticallyOption: true,
    NSInferMappingModelAutomaticallyOption: true
]
```

2. **Custom Mapping Model** — for complex transformations (splitting entities, data computation). You create an `NSMappingModel` with `NSEntityMigrationPolicy` subclasses.

For production apps, always version your `.xcdatamodeld` and test migrations before shipping.

---

### Q18. How does `automaticallyMergesChangesFromParent` work?

**A:** When set to `true` on the view context, CoreData listens for `NSManagedObjectContextDidSave` notifications from other contexts (background contexts) and automatically merges their changes into the view context. This keeps the UI in sync with background writes.

```swift
container.viewContext.automaticallyMergesChangesFromParent = true
```

Without this, a background import would save successfully but the list view would show stale data until the next explicit `loadExpenses()` call.

---

### Q19. How would you improve this app for production?

**A:**

| Area | Improvement |
|---|---|
| **Error handling** | Replace `print()` with OSLog; surface errors in a dedicated error state view |
| **Background processing** | Move bulk imports/exports to `performBackgroundTask` |
| **Migrations** | Version the model; enable lightweight migration |
| **Testing** | MockRepository for ViewModel unit tests; in-memory store for integration tests |
| **Charts** | Add `Charts` framework for monthly spending breakdown by category |
| **iCloud sync** | Replace `NSPersistentContainer` with `NSPersistentCloudKitContainer` |
| **Pagination** | `request.fetchLimit` + `request.fetchOffset` for large datasets |
| **Security** | Biometric authentication; encrypt sensitive fields |

---

### Q20. What is the difference between `fetchLimit` and `fetchBatchSize`?

**A:**
- **`fetchLimit`** — caps the total number of objects returned. Use when you only need the top N results (e.g., top 5 recent expenses).
- **`fetchBatchSize`** — CoreData fetches objects in batches of this size as they're accessed, keeping memory low for large result sets. The fetch request appears to return all objects, but they're faulted in on demand. Ideal for `NSFetchedResultsController` backing a long list.

```swift
request.fetchLimit = 1         // "give me exactly 1 result"
request.fetchBatchSize = 20    // "load 20 at a time as I scroll"
```

---

*Good luck in your interviews!*
