import Foundation

struct FileNode: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    var size: UInt64
    var children: [FileNode]?
    var isDirectory: Bool
    var isLoaded: Bool = false // For lazy loading
}
