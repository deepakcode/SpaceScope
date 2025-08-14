import SwiftUI

struct FileTreeView: View {
    @ObservedObject var viewModel: FileTreeViewModel
    @Binding var node: FileNode
    let maxSize: UInt64
    let filterSettings: FilterSettings // Consolidated filters
    
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
                    ForEach(children.indices, id: \.self) { i in
                        let child = children[i]
                        let passesSizeFilter = !filterSettings.hideSmallFiles || child.size >= minSizeBytes
                        let passesHiddenFilter = !filterSettings.hideHiddenFiles || !child.name.hasPrefix(".")
                        
                        if passesSizeFilter && passesHiddenFilter {
                            FileTreeView(
                                viewModel: viewModel,
                                node: Binding(
                                    get: { node.children![i] },
                                    set: { newValue in
                                        node.children![i] = newValue
                                    }
                                ),
                                maxSize: maxSize,
                                filterSettings: filterSettings
                            )
                            .padding(.leading, 20)
                        }
                    }
                }
            },
            label: {
                Text("\(node.name) - \(formatSize(node.size))")
                    .foregroundColor(colorForSize(node.size))
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
