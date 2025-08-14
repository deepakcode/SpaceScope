import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FileTreeViewModel()
    @State private var filterSettings = FilterSettings()
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Top settings bar with primary select button + clearly labeled toggles
            HStack(spacing: 20) {
                Button(action: {
                    selectFolder()
                }) {
                    Text("Select Folder")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(1)
                    
                }
                
                Toggle(isOn: $filterSettings.hideSmallFiles) {
                    Text("Hide files smaller than 10 MB")
                }
                .toggleStyle(SwitchToggleStyle())
                
                Toggle(isOn: $filterSettings.greySmallFiles) {
                    Text("Grey out files smaller than 1 GB")
                }
                .toggleStyle(SwitchToggleStyle())
                
                Spacer()
                
                Toggle(isOn: $filterSettings.hideHiddenFiles) {
                    Text("Hide hidden/system files")
                }
                .toggleStyle(SwitchToggleStyle())
            }
            .padding(10)
            .background(Color(NSColor.windowBackgroundColor))
            .overlay(Divider(), alignment: .bottom)
            
            // Main content area
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let _ = viewModel.rootNode {
                ScrollView {
                    FileTreeView(
                        viewModel: viewModel,
                        node: Binding($viewModel.rootNode)!,
                        maxSize: viewModel.rootNode?.size ?? 0,
                        filterSettings: filterSettings
                    )
                }
            } else {
                Text("Select a folder to start scanning")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
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
