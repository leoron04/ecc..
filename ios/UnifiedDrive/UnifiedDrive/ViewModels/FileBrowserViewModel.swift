import Foundation

@MainActor
final class FileBrowserViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published var items: [WebDAVItem] = []
    @Published var cachedEntries: [CachedFile] = []
    @Published var state: LoadState = .idle
    @Published var previewItem: LocalFilePresentation?
    @Published var shareItem: LocalFilePresentation?
    @Published var playerContext: PlayerContext?
    @Published var errorMessage: String?
    @Published var metrics = BrowserMetrics()

    let path: String
    private let client: WebDAVClient
    private let cache: DiskCache

    init(path: String, client: WebDAVClient, cache: DiskCache) {
        self.path = WebDAVPath.normalized(path)
        self.client = client
        self.cache = cache
    }

    var title: String {
        path == "/" ? "UnifiedDrive" : WebDAVPath.displayName(for: path)
    }

    func load() async -> Bool {
        state = .loading
        let startedAt = Date()
        do {
            items = try await client.listDirectory(path: path)
            cachedEntries = cache.recentEntries()
            metrics.lastRefresh = Date()
            metrics.lastLatency = Date().timeIntervalSince(startedAt)
            state = .loaded
            return true
        } catch {
            // Se l'hub non risponde, la UI passa alla lista dei file in cache.
            cachedEntries = cache.recentEntries()
            metrics.lastRefresh = Date()
            metrics.lastLatency = nil
            state = .failed(error.localizedDescription)
            return false
        }
    }

    func open(_ item: WebDAVItem) async {
        guard !item.isDirectory else { return }

        do {
            switch item.type {
            case .video, .audio:
                playerContext = PlayerContext(url: client.url(for: item), headers: client.authHeaders, title: item.name)
            case .image, .pdf:
                previewItem = LocalFilePresentation(url: try await cachedOrDownloadedURL(for: item))
            case .document, .other, .folder:
                shareItem = LocalFilePresentation(url: try await cachedOrDownloadedURL(for: item))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func share(_ item: WebDAVItem) async {
        guard !item.isDirectory else { return }

        do {
            shareItem = LocalFilePresentation(url: try await cachedOrDownloadedURL(for: item))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cacheForOffline(_ item: WebDAVItem) async {
        guard !item.isDirectory else { return }

        do {
            _ = try await cachedOrDownloadedURL(for: item)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openCached(_ entry: CachedFile) {
        guard let url = cache.cachedURL(for: entry) else {
            errorMessage = UnifiedDriveError.unsupportedCachedFile.localizedDescription
            return
        }

        switch entry.item.type {
        case .video, .audio:
            playerContext = PlayerContext(url: url, headers: [:], title: entry.name)
        case .image, .pdf:
            previewItem = LocalFilePresentation(url: url)
        default:
            shareItem = LocalFilePresentation(url: url)
        }
    }

    func upload(fileURL: URL) async -> Bool {
        do {
            let accessed = fileURL.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }

            try await client.upload(fileURL: fileURL, to: path)
            return await load()
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func upload(data: Data, named filename: String) async -> Bool {
        do {
            try await client.upload(data: data, named: filename, to: path)
            return await load()
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func createFolder(named name: String) async -> Bool {
        do {
            try await client.createFolder(named: name, in: path)
            return await load()
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func rename(item: WebDAVItem, to name: String) async -> Bool {
        do {
            try await client.rename(item: item, to: name)
            return await load()
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func delete(item: WebDAVItem) async -> Bool {
        do {
            try await client.delete(item: item)
            return await load()
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func cachedOrDownloadedURL(for item: WebDAVItem) async throws -> URL {
        if let cached = cache.cachedURL(for: item) {
            return cached
        }

        let data = try await client.download(item: item)
        return try cache.store(data: data, for: item)
    }

}

struct LocalFilePresentation: Identifiable, Equatable {
    let id = UUID()
    let url: URL
}

struct PlayerContext: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let headers: [String: String]
    let title: String
}
