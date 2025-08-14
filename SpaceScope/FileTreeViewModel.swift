import Foundation
import SwiftUI

class FileTreeViewModel: ObservableObject {
    @Published var rootNode: FileNode?
    @Published var isLoading: Bool = false
    
    func scanDirectory(at url: URL) {
        DispatchQueue.main.async {
            self.rootNode = nil      // Clear old data
            self.isLoading = true    // Start loading
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let size = self.calculateFolderSize(url: url)
            let root = FileNode(url: url, name: url.lastPathComponent, size: size, children: nil, isDirectory: true)
            
            DispatchQueue.main.async {
                self.rootNode = root
                self.isLoading = false // Done
            }
        }
    }
    
    func loadChildren(into node: Binding<FileNode>) {
        DispatchQueue.main.async {
            self.isLoading = true // Show progress while expanding
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            var children: [FileNode] = []
            
            if let contents = try? FileManager.default.contentsOfDirectory(
                at: node.wrappedValue.url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            ) {
                for item in contents {
                    let isDirectory = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                    if isDirectory {
                        let size = self.calculateFolderSize(url: item)
                        children.append(FileNode(url: item, name: item.lastPathComponent, size: size, children: nil, isDirectory: true))
                    } else {
                        let fileSize = (try? item.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                        children.append(FileNode(url: item, name: item.lastPathComponent, size: UInt64(fileSize), children: nil, isDirectory: false))
                    }
                }
            }
            
            DispatchQueue.main.async {
                node.wrappedValue.children = children.sorted(by: { $0.size > $1.size })
                node.wrappedValue.isLoaded = true
                self.isLoading = false // Hide progress after load
            }
        }
    }
    
    private func calculateFolderSize(url: URL) -> UInt64 {
        var total: UInt64 = 0
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                    total += UInt64(fileSize)
                }
            }
        }
        return total
    }
}
