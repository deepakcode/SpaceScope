import Foundation

struct FilterSettings {
    var hideSmallFiles: Bool = true
    var hideHiddenFiles: Bool = false
    var greySmallFiles: Bool = true // New setting for greying out files < 1GB
}
