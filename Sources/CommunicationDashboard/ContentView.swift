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
                if #available(macOS 14.0, *) {
                    ContentUnavailableView(
                        "No Selection",
                        systemImage: "sidebar.left",
                        description: Text("Select an item from the sidebar")
                    )
                } else {
                    VStack {
                        Image(systemName: "sidebar.left")
                            .font(.largeTitle)
                        Text("No Selection")
                            .font(.title)
                        Text("Select an item from the sidebar")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
