import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = FileTreeViewModel()
    @State private var hideSmallFiles = true
    
    var body: some View {
        VStack {
            HStack {
                Button("Select Folder") {
                    selectFolder()
                }
                .padding(.trailing, 10)
                
                Toggle("Hide files < 10 MB", isOn: $hideSmallFiles)
                    .toggleStyle(SwitchToggleStyle())
                    .padding(.trailing, 20)
                
                Spacer()
            }
            .padding(.top, 10)
            
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }
            
            if let _ = viewModel.rootNode, !viewModel.isLoading {
                ScrollView {
                    FileTreeView(
                        viewModel: viewModel,
                        node: Binding($viewModel.rootNode)!,
                        maxSize: viewModel.rootNode?.size ?? 0,
                        hideSmallFiles: hideSmallFiles
                    )
                }
            } else if !viewModel.isLoading {
                Text("Select a folder to start scanning")
                    .foregroundColor(.secondary)
                    .padding()
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
