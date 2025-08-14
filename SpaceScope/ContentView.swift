import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FileTreeViewModel()
    @State private var filterSettings = FilterSettings() // Use the new struct
    @State private var searchText: String = "" // New state for search
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                VStack {
                    ProgressView(viewModel.loadingMessage.isEmpty ? "Loading..." : viewModel.loadingMessage)
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                    Text(viewModel.loadingMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.bottom, 10)
                }
            } else if let _ = viewModel.rootNode {
                ScrollView {
                    FileTreeView(
                        viewModel: viewModel,
                        node: Binding($viewModel.rootNode)!,
                        maxSize: viewModel.rootNode?.size ?? 0,
                        filterSettings: filterSettings, // Pass the entire struct
                        searchText: searchText // Pass search text
                    )
                }
            } else {
                Text("Select a folder to start scanning")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .toolbar { // Using the toolbar modifier for better organization
            ToolbarItem(placement: .navigation) {
                Button("Select Folder") {
                    selectFolder()
                }
            }
            ToolbarItem(placement: .navigation) {
                TextField("Search", text: $searchText, prompt: Text("Search"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
            }
            ToolbarItem(placement: .automatic) {
                Toggle("Hide files < 10 MB", isOn: $filterSettings.hideSmallFiles)
                    .toggleStyle(SwitchToggleStyle())
            }
            ToolbarItem(placement: .automatic) {
                Toggle("Hide hidden files", isOn: $filterSettings.hideHiddenFiles)
                    .toggleStyle(SwitchToggleStyle())
            }
            ToolbarItem(placement: .automatic) {
                Toggle("Grey out files < 1 GB", isOn: $filterSettings.greySmallFiles)
                    .toggleStyle(SwitchToggleStyle())
            }
            ToolbarItem(placement: .automatic) {
                Button("Manage Skipped Folders") {
                    // For now, print to console. In a real app, this would open a management sheet/window.
                    print("Skipped folders: \(viewModel.skippedFolders.map { $0.lastPathComponent }.joined(separator: ", "))")
                }
            }
        }
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            viewModel.scanDirectory(at: url)
        }
    }
}
