import SwiftUI
import UniformTypeIdentifiers

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool,
                             transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct ReorderableForEach<Data, Content>: View
where Data: Identifiable & Hashable, Content: View {
  @Binding var data: [Data]
  @Binding var allowReordering: Bool
  let content: (Data, Bool) -> Content

  @State private var dragged: Data?

  var body: some View {
    ForEach(data) { item in
      let isDragged = dragged?.id == item.id
        content(item, isDragged && allowReordering)
            .opacity(isDragged && allowReordering ? 0.001 : 1)
            .if(allowReordering) { view in
                view.draggable("\(item.id)") {
                    Color.clear.frame(width: 1, height: 1) // invisible preview
                }
            }
        .onDragBegan {
          if allowReordering { dragged = item }
        }
        .dropDestination(for: String.self) { items, location in
          // Finish
          dragged = nil
          return true
        } isTargeted: { targeted in
          guard allowReordering,
                targeted,
                let dragging = dragged,
                dragging.id != item.id,
                let from = data.firstIndex(of: dragging),
                let to = data.firstIndex(of: item) else { return }

          withAnimation(.easeInOut(duration: 0.12)) {
            data.move(fromOffsets: IndexSet(integer: from),
                      toOffset: (to > from) ? to + 1 : to)
          }
        }
        .onDisappear {
          if dragged?.id == item.id { dragged = nil }
        }
    }
  }
}

// Small helper to detect drag start (no direct API; works by timing)
fileprivate extension View {
  func onDragBegan(_ action: @escaping () -> Void) -> some View {
    self.onLongPressGesture(minimumDuration: 0.01, perform: action)
  }
}

struct ReorderingVStackTest: View {
  @State private var data = ["Apple", "Orange", "Banana", "Lemon", "Tangerine"]
  @State private var allowReordering = false
  
  var body: some View {
    VStack {
      Toggle("Allow reordering", isOn: $allowReordering)
        .frame(width: 200)
        .padding(.bottom, 30)
      VStack {
          ReorderableForEach(data: $data, allowReordering: $allowReordering) { item, isDragged in
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
          ReorderableForEach(data: $data, allowReordering: $allowReordering) { item, isDragged in
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

struct ReorderingVStackTest_Previews: PreviewProvider {
  static var previews: some View {
    ReorderingVStackTest()
  }
}

struct ReorderingGridTest_Previews: PreviewProvider {
  static var previews: some View {
    ReorderingVGridTest()
  }
}
