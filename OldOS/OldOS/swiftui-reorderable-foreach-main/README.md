# SwiftUIReorderableForEach

Easily implement **drag & drop to reorder items in SwiftUI**.

This package contains a generic **ReoderableForEach** component, which can then be plugged into **any layout**, such as `VStack`, `LazyVGrid`, etc. The end result looks like this:

<table style="border: none;">
  <tr>
    <td><img src="https://github.com/globulus/swiftui-reorderable-foreach/blob/main/Images/previewGrid.gif?raw=true" alt="Grid" /></td>
    <td><img src="https://github.com/globulus/swiftui-reorderable-foreach/blob/main/Images/previewStack.gif?raw=true" alt="Stack" /></td>
  </tr> 
</table>

## Features

* Supports any `Hashable` data.
* Works with any SwiftUI layout.
* Binding to dynamically enable/disable reordering functionality.
* Custom item rendering with additional info on if the current item is being dragged or not.

## Installation

This component is distrubuted as a **Swift package**. Just add this URL to your package list:

```text
https://github.com/globulus/swiftui-reorderable-foreach
```

You can also use **CocoaPods**:

```ruby
pod 'SwiftUIReorderableForEach', '~> 1.0.0'
```

## Sample usage

### VStack

```swift
struct ReorderingVStackTest: View {
  @State private var data = ["Apple", "Orange", "Banana", "Lemon", "Tangerine"]
  @State private var allowReordering = false
  
  var body: some View {
    VStack {
      Toggle("Allow reordering", isOn: $allowReordering)
        .frame(width: 200)
        .padding(.bottom, 30)
      VStack {
        ReorderableForEach($data, allowReordering: $allowReordering) { item, isDragged in
          Text(item)
            .font(.title)
            .padding()
            .frame(minWidth: 200, minHeight: 50)
            .border(Color.blue)
            .background(Color.red.opacity(0.9))
            .overlay(isDragged ? Color.white.opacity(0.6) : Color.clear)
        }
      }
    }
  }
}
```

### LazyVGrid

```swift
struct ReorderingVGridTest: View {
  @State private var data = ["Apple", "Orange", "Banana", "Lemon", "Tangerine"]
  @State private var allowReordering = false
  
  var body: some View {
    VStack {
      Toggle("Allow reordering", isOn: $allowReordering)
        .frame(width: 200)
        .padding(.bottom, 30)
      LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
      ]) {
        ReorderableForEach($data, allowReordering: $allowReordering) { item, isDragged in
          Text(item)
            .font(.title)
            .padding()
            .frame(minWidth: 150, minHeight: 50)
            .border(Color.blue)
            .background(Color.red.opacity(0.9))
            .overlay(isDragged ? Color.white.opacity(0.6) : Color.clear)
        }
      }
    }
    .padding()
  }
}
```

## Recipe

Check out [this recipe](https://swiftuirecipes.com/blog/swiftui-drag-to-reorder-foreach-stack-grid) for in-depth description of the component and its code. Check out [SwiftUIRecipes.com](https://swiftuirecipes.com) for more **SwiftUI recipes**!

## Changelog

* 1.0.0 - Initial release.
