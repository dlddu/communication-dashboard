import SwiftUI

struct ContentView: View {
    @State private var selection: String?

    var body: some View {
        NavigationSplitView {
            List {
                Text("Sidebar Item 1")
                Text("Sidebar Item 2")
            }
            .navigationTitle("Communication Dashboard")
        } detail: {
            if let selection {
                Text("Selected: \(selection)")
            } else {
                ContentUnavailableView(
                    "No Selection",
                    systemImage: "sidebar.left",
                    description: Text("Select an item from the sidebar")
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
