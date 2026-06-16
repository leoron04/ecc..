import Foundation

struct CachedFile: Identifiable, Codable, Hashable {
    let path: String
    let name: String
    let localFilename: String
    let contentType: String?
    let cachedAt: Date
    let size: Int64?

    var id: String { path }

    var item: WebDAVItem {
        WebDAVItem(
            path: path,
            name: name,
            isDirectory: false,
            size: size,
            lastModified: cachedAt,
            contentType: contentType
        )
    }
}

