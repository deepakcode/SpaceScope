import SwiftUI

struct FileTreeView: View {
    @ObservedObject var viewModel: FileTreeViewModel
    @Binding var node: FileNode
    let maxSize: UInt64
    let filterSettings: FilterSettings // Consolidated filters
    let searchText: String // New property for search text
    
    var body: some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { node.isLoaded && node.children != nil },
                set: { expand in
                    if expand && node.isDirectory && !node.isLoaded {
                        viewModel.loadChildren(into: $node)
                    }
                }
            ),
            content: {
                if let children = node.children {
                    let filteredChildren = children.filter { child in
                        let passesSizeFilter = !filterSettings.hideSmallFiles || child.size >= minSizeBytes
                        let passesHiddenFilter = !filterSettings.hideHiddenFiles || !child.name.hasPrefix(".")
                        let passesSearchFilter = searchText.isEmpty || child.name.localizedCaseInsensitiveContains(searchText)
                        
                        return passesSizeFilter && passesHiddenFilter && passesSearchFilter
                    }
                    
                    ForEach(filteredChildren.indices, id: \.self) { i in
                        FileTreeView(
                            viewModel: viewModel,
                            node: Binding(
                                get: { filteredChildren[i] },
                                set: { newValue in
                                    if let index = node.children?.firstIndex(where: { $0.id == filteredChildren[i].id }) {
                                        node.children?[index] = newValue
                                    }
                                }
                            ),
                            maxSize: maxSize,
                            filterSettings: filterSettings,
                            searchText: searchText
                        )
                        .padding(.leading, 20)
                    }
                }
            },
            label: {
                Text("\(node.name) - \(formatSize(node.size))")
                    .foregroundColor(colorForSize(node.size))
                    .contextMenu {
                        Button(action: {
                            if viewModel.skippedFolders.contains(node.url) {
                                viewModel.skippedFolders.remove(node.url)
                            } else {
                                viewModel.skippedFolders.insert(node.url)
                            }
                        }) {
                            Text(viewModel.skippedFolders.contains(node.url) ? "Unskip Folder" : "Skip Folder")
                        }
                    }
            }
        )
    }
    
    private let minSizeBytes: UInt64 = 10 * 1024 * 1024 // 10MB
    private let oneGB: UInt64 = 1 * 1024 * 1024 * 1024 // 1GB for greying out
    
    private func formatSize(_ size: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    private func colorForSize(_ size: UInt64) -> Color {
        if filterSettings.greySmallFiles && size < oneGB {
            return Color.gray.opacity(0.6)
        }
        let ratio = Double(size) / Double(maxSize)
        if ratio > 0.66 { return .red }
        else if ratio > 0.33 { return .orange }
        else { return .green }
    }
}
