import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FileTreeViewModel()
    @State private var filterSettings = FilterSettings() // Use the new struct
    
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
                        filterSettings: filterSettings // Pass the entire struct
                    )
                }
            } else {
                Text("Select a folder to start scanning")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .toolbar { // Toolbar with descriptive labels
            ToolbarItem(placement: .navigation) {
                Button {
                    selectFolder()
                } label: {
                    Label("Select Folder", systemImage: "folder")
                }
                .keyboardShortcut("o", modifiers: [.command]) // Optional shortcut
                .buttonStyle(.borderedProminent) // Highlight as primary button
            }
            ToolbarItem(placement: .automatic) {
                Toggle(isOn: $filterSettings.hideSmallFiles) {
                    Label("Hide files < 10 MB", systemImage: "eye.slash")
                }
                .toggleStyle(SwitchToggleStyle())
            }
            ToolbarItem(placement: .automatic) {
                Toggle(isOn: $filterSettings.hideHiddenFiles) {
                    Label("Hide hidden files", systemImage: "eye.slash.fill")
                }
                .toggleStyle(SwitchToggleStyle())
            }
            ToolbarItem(placement: .automatic) {
                Toggle(isOn: $filterSettings.greySmallFiles) {
                    Label("Grey out files < 1 GB", systemImage: "circle.lefthalf.filled")
                }
                .toggleStyle(SwitchToggleStyle())
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    print("Skipped folders: \(viewModel.skippedFolders.map { $0.lastPathComponent }.joined(separator: ", "))")
                } label: {
                    Label("Manage Skipped Folders", systemImage: "folder.badge.minus")
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
