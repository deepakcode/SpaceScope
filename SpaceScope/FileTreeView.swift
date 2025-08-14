import SwiftUI

struct FileTreeView: View {
    @ObservedObject var viewModel: FileTreeViewModel
    @Binding var node: FileNode
    let maxSize: UInt64
    let hideSmallFiles: Bool // NEW: pass toggle state from ContentView
    
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
                    let filteredChildren = hideSmallFiles
                        ? children.filter { $0.size >= minSizeBytes }
                        : children
                    
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
                            hideSmallFiles: hideSmallFiles
                        )
                        .padding(.leading, 20)
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
    
    private func formatSize(_ size: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    private func colorForSize(_ size: UInt64) -> Color {
        let oneGB: UInt64 = 1 * 1024 * 1024 * 1024
        if size < oneGB {
            return Color.gray.opacity(0.6)
        }
        let ratio = Double(size) / Double(maxSize)
        if ratio > 0.66 { return .red }
        else if ratio > 0.33 { return .orange }
        else { return .green }
    }
}
