import Foundation

final class WebDAVClient {
    let configuration: ServerConfiguration
    private let session: URLSession

    init(configuration: ServerConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    var authHeaders: [String: String] {
        ["Authorization": configuration.authorizationHeader]
    }

    func verifyRoot() async throws {
        _ = try await listDirectory(path: "/")
    }

    func listDirectory(path: String) async throws -> [WebDAVItem] {
        // PROPFIND Depth 1 legge solo i figli diretti della cartella corrente.
        var request = makeRequest(path: path, method: "PROPFIND")
        request.setValue("1", forHTTPHeaderField: "Depth")
        request.setValue("application/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("""
        <?xml version="1.0" encoding="utf-8"?>
        <d:propfind xmlns:d="DAV:">
          <d:prop>
            <d:displayname/>
            <d:getcontentlength/>
            <d:getlastmodified/>
            <d:getcontenttype/>
            <d:resourcetype/>
          </d:prop>
        </d:propfind>
        """.utf8)

        let (data, response) = try await session.data(for: request)
        try validate(response: response, allowedStatusCodes: [200, 207])

        let parser = WebDAVXMLParser(requestedPath: path)
        return try parser.parse(data: data, baseURL: configuration.baseURL)
            .sorted { lhs, rhs in
                if lhs.isDirectory != rhs.isDirectory {
                    return lhs.isDirectory && !rhs.isDirectory
                }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
    }

    func download(item: WebDAVItem) async throws -> Data {
        let request = makeRequest(path: item.path, method: "GET")
        let (data, response) = try await session.data(for: request)
        try validate(response: response, allowedStatusCodes: [200, 206])
        return data
    }

    func upload(data: Data, named name: String, to parentPath: String) async throws {
        let destination = WebDAVPath.childPath(parent: parentPath, name: name)
        var request = makeRequest(path: destination, method: "PUT")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await session.upload(for: request, from: data)
        try validate(response: response, allowedStatusCodes: [200, 201, 204])
    }

    func upload(fileURL: URL, to parentPath: String) async throws {
        let destination = WebDAVPath.childPath(parent: parentPath, name: fileURL.lastPathComponent)
        let request = makeRequest(path: destination, method: "PUT")
        let (_, response) = try await session.upload(for: request, fromFile: fileURL)
        try validate(response: response, allowedStatusCodes: [200, 201, 204])
    }

    func createFolder(named name: String, in parentPath: String) async throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw UnifiedDriveError.emptyName }
        let destination = WebDAVPath.childPath(parent: parentPath, name: trimmedName, isDirectory: true)
        let request = makeRequest(path: destination, method: "MKCOL")
        let (_, response) = try await session.data(for: request)
        try validate(response: response, allowedStatusCodes: [201, 405])
    }

    func rename(item: WebDAVItem, to newName: String) async throws {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw UnifiedDriveError.emptyName }

        // In WebDAV la rinomina e una MOVE verso lo stesso parent con nome nuovo.
        let parent = WebDAVPath.parentPath(of: item.path)
        let destinationPath = WebDAVPath.childPath(parent: parent, name: trimmedName, isDirectory: item.isDirectory)
        var request = makeRequest(path: item.path, method: "MOVE")
        request.setValue(absoluteURL(path: destinationPath).absoluteString, forHTTPHeaderField: "Destination")
        request.setValue("T", forHTTPHeaderField: "Overwrite")

        let (_, response) = try await session.data(for: request)
        try validate(response: response, allowedStatusCodes: [200, 201, 204])
    }

    func delete(item: WebDAVItem) async throws {
        let request = makeRequest(path: item.path, method: "DELETE")
        let (_, response) = try await session.data(for: request)
        try validate(response: response, allowedStatusCodes: [200, 202, 204])
    }

    func url(for item: WebDAVItem) -> URL {
        absoluteURL(path: item.path)
    }

    private func makeRequest(path: String, method: String) -> URLRequest {
        var request = URLRequest(url: absoluteURL(path: path))
        request.httpMethod = method
        // Basic Auth esplicita: nessun account esterno, nessun challenge handler.
        request.setValue(configuration.authorizationHeader, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        return request
    }

    private func absoluteURL(path: String) -> URL {
        var components = URLComponents(url: configuration.baseURL, resolvingAgainstBaseURL: false)!
        components.percentEncodedPath = WebDAVPath.encodedPath(path)
        return components.url!
    }

    private func validate(response: URLResponse, allowedStatusCodes: Set<Int>) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UnifiedDriveError.invalidResponse
        }

        guard allowedStatusCodes.contains(httpResponse.statusCode) else {
            throw UnifiedDriveError.httpStatus(httpResponse.statusCode)
        }
    }
}
