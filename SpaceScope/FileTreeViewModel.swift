import Foundation
import SwiftUI

class FileTreeViewModel: ObservableObject {
    @Published var rootNode: FileNode?
    @Published var isLoading: Bool = false
    @Published var loadingMessage: String = ""
    
    func scanDirectory(at url: URL) {
        DispatchQueue.main.async {
            self.rootNode = nil
            self.isLoading = true
            self.loadingMessage = "Scanning root folder: \(url.path)"
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let size = self.calculateFolderSize(url: url, progressPath: url.path)
            let root = FileNode(url: url, name: url.lastPathComponent, size: size, children: nil, isDirectory: true)
            
            DispatchQueue.main.async {
                self.rootNode = root
                self.isLoading = false
                self.loadingMessage = ""
            }
        }
    }
    
    func loadChildren(into node: Binding<FileNode>) {
        DispatchQueue.main.async {
            self.isLoading = true
            self.loadingMessage = "Loading: \(node.wrappedValue.url.path)"
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            var children: [FileNode] = []
            
            if let contents = try? FileManager.default.contentsOfDirectory(
                at: node.wrappedValue.url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                options: [] // ✅ No .skipsHiddenFiles → include hidden files
            ) {
                for item in contents {
                    let isDirectory = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                    if isDirectory {
                        let size = self.calculateFolderSize(url: item, progressPath: item.path)
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
                self.isLoading = false
                self.loadingMessage = ""
            }
        }
    }
    
    private func calculateFolderSize(url: URL, progressPath: String) -> UInt64 {
        var total: UInt64 = 0
        if let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [] // ✅ No .skipsHiddenFiles → include hidden files
        ) {
            for case let fileURL as URL in enumerator {
                DispatchQueue.main.async {
                    self.loadingMessage = "Scanning: \(progressPath)"
                }
                if let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                    total += UInt64(fileSize)
                }
            }
        }
        return total
    }
}
