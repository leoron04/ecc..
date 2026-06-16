import CryptoKit
import Foundation

final class DiskCache {
    private let directory: URL
    private let indexURL: URL
    private let fileManager = FileManager.default

    init() {
        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        directory = base.appendingPathComponent("UnifiedDriveFileCache", isDirectory: true)
        indexURL = directory.appendingPathComponent("index.json")
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func store(data: Data, for item: WebDAVItem) throws -> URL {
        let localURL = localURL(for: item)
        try data.write(to: localURL, options: .atomic)

        // Mantiene una lista breve di file aperti di recente per l'uso offline.
        var entries = loadIndex()
        entries.removeAll { $0.path == item.path }
        entries.insert(
            CachedFile(
                path: item.path,
                name: item.name,
                localFilename: localURL.lastPathComponent,
                contentType: item.contentType,
                cachedAt: Date(),
                size: Int64(data.count)
            ),
            at: 0
        )

        saveIndex(Array(entries.prefix(50)))
        return localURL
    }

    func cachedURL(for item: WebDAVItem) -> URL? {
        let url = localURL(for: item)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func cachedURL(for entry: CachedFile) -> URL? {
        let url = directory.appendingPathComponent(entry.localFilename)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func recentEntries() -> [CachedFile] {
        loadIndex().filter { cachedURL(for: $0) != nil }
    }

    private func localURL(for item: WebDAVItem) -> URL {
        let digest = SHA256.hash(data: Data(item.path.utf8))
        let hash = digest.map { String(format: "%02x", $0) }.joined()
        let ext = URL(fileURLWithPath: item.name).pathExtension
        let filename = ext.isEmpty ? hash : "\(hash).\(ext)"
        return directory.appendingPathComponent(filename)
    }

    private func loadIndex() -> [CachedFile] {
        guard let data = try? Data(contentsOf: indexURL) else { return [] }
        return (try? JSONDecoder().decode([CachedFile].self, from: data)) ?? []
    }

    private func saveIndex(_ entries: [CachedFile]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
}
