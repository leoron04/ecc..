import Foundation

enum WebDAVPath {
    static func normalized(_ path: String) -> String {
        var value = path.removingPercentEncoding ?? path
        if value.isEmpty { value = "/" }
        if !value.hasPrefix("/") { value = "/" + value }
        while value.contains("//") {
            value = value.replacingOccurrences(of: "//", with: "/")
        }
        return value
    }

    static func childPath(parent: String, name: String, isDirectory: Bool = false) -> String {
        let cleanParent = normalized(parent)
        let separator = cleanParent.hasSuffix("/") ? "" : "/"
        let suffix = isDirectory ? "/" : ""
        return normalized("\(cleanParent)\(separator)\(name)\(suffix)")
    }

    static func parentPath(of path: String) -> String {
        let normalizedPath = normalized(path).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let parts = normalizedPath.split(separator: "/")
        guard parts.count > 1 else { return "/" }
        return "/" + parts.dropLast().joined(separator: "/") + "/"
    }

    static func encodedPath(_ path: String) -> String {
        let normalizedPath = normalized(path)
        if normalizedPath == "/" { return "/" }

        let keepsTrailingSlash = normalizedPath.hasSuffix("/")
        let encoded = normalizedPath
            .split(separator: "/", omittingEmptySubsequences: true)
            .map { segment in
                String(segment).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String(segment)
            }
            .joined(separator: "/")

        return "/" + encoded + (keepsTrailingSlash ? "/" : "")
    }

    static func displayName(for path: String) -> String {
        let trimmed = normalized(path).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return trimmed.split(separator: "/").last.map(String.init) ?? "UnifiedDrive"
    }
}

