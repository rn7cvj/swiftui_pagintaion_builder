# swiftui_pagintaion_builder

Reusable Swift Package with a pagination controller and SwiftUI list builder.

## Included API

- `MPBController`
- `MPBControllerState`
- `MPBBuilder`
- `MPBIdentifiable`

## Requirements

- iOS 15+
- macOS 12+
- Swift 5.9+

## Installation (SPM)

Local package:

```swift
.package(path: "swiftui_pagintaion_builder")
```

Remote package:

```swift
.package(url: "https://github.com/rn7cvj/swiftui_pagintaion_builder.git", from: "1.0.0")
```

Then add the product:

```swift
.product(name: "SwiftUIPagintaionBuilder", package: "swiftui_pagintaion_builder")
```

## Quick Example

```swift
import SwiftUI
import SwiftUIPagintaionBuilder

struct FeedItem: MPBIdentifiable {
    let id: UUID
    let mpbId: Int
    let title: String
}

@MainActor
final class FeedViewModel: ObservableObject {
    let controller = MPBController<FeedItem>(
        dataLoader: { pageIndex, pageSize, _ in
            // Load your data from API/storage here.
            []
        }
    )
}

struct FeedView: View {
    @StateObject private var vm = FeedViewModel()

    var body: some View {
        MPBBuilder(
            controller: vm.controller,
            itemBuilder: { _, item, _, _, _ in
                Text(item.title)
            },
            firstLoadingBuilder: { _ in
                ProgressView()
            },
            noItemBuilder: { _ in
                Text("No items")
            }
        )
    }
}
```
