# Expense Tracker

> SwiftUI expense entry, filtering, and Core Data persistence.

## What is included

- Add, edit, and delete expenses
- Category filtering, search, and monthly totals
- Repository-backed Core Data storage

## Current scope

Expense records belong to the local demo store; no bank connection is provided.

## Open in Xcode

| Project | Shared scheme |
| --- | --- |
| `ExpenseTracker.xcodeproj` | `ExpenseTracker` |

Select a simulator compatible with the deployment target in Build Settings and press **⌘R**. Physical-device deployment requires your own development team and provisioning. Simulator build checks use Xcode 27 and the installed iOS 27 SDK.

```bash
git clone https://github.com/sachinarkasali944/ExpenseTracker.git
cd ExpenseTracker
xcodebuild -project "ExpenseTracker.xcodeproj" -scheme "ExpenseTracker" \
  -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO build
```

## Further reading

[Original project guide](./PROJECT_GUIDE.md). It is retained as study material; the project paths and scope in this README describe this uploaded copy.

## Repository hygiene

The repository includes source, project configuration, and shared schemes. Personal Xcode state, build products, duplicate zip archives, and signing credentials are excluded. This repository is private; authenticate with GitHub to clone it.
