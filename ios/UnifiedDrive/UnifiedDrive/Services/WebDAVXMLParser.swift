import Foundation

final class WebDAVXMLParser: NSObject, XMLParserDelegate {
    private struct MutableItem {
        var href = ""
        var displayName = ""
        var size: Int64?
        var lastModified: Date?
        var contentType: String?
        var isDirectory = false
    }

    private var items: [MutableItem] = []
    private var currentItem: MutableItem?
    private var currentElement = ""
    private var textBuffer = ""
    private let requestedPath: String

    init(requestedPath: String) {
        self.requestedPath = WebDAVPath.normalized(requestedPath)
    }

    func parse(data: Data, baseURL: URL) throws -> [WebDAVItem] {
        // Parser SAX minimale per le risposte multistatus WebDAV.
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false

        guard parser.parse() else {
            throw UnifiedDriveError.xmlParsingFailed
        }

        let requestedComparablePath = comparablePath(requestedPath)
        return items.compactMap { mutable in
            let path = pathFromHref(mutable.href, baseURL: baseURL)
            guard comparablePath(path) != requestedComparablePath else { return nil }

            let fallbackName = WebDAVPath.displayName(for: path)
            let name = mutable.displayName.removingPercentEncoding?.nilIfEmpty
                ?? mutable.displayName.nilIfEmpty
                ?? fallbackName

            return WebDAVItem(
                path: path,
                name: name,
                isDirectory: mutable.isDirectory,
                size: mutable.size,
                lastModified: mutable.lastModified,
                contentType: mutable.contentType
            )
        }
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        let name = localName(elementName)
        currentElement = name
        textBuffer = ""

        if name == "response" {
            currentItem = MutableItem()
        } else if name == "collection" {
            currentItem?.isDirectory = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        textBuffer += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let name = localName(elementName)
        let value = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)

        switch name {
        case "href":
            currentItem?.href = value
        case "displayname":
            currentItem?.displayName = value
        case "getcontentlength":
            currentItem?.size = Int64(value)
        case "getlastmodified":
            currentItem?.lastModified = HTTPDateFormatter.date(from: value)
        case "getcontenttype":
            currentItem?.contentType = value.nilIfEmpty
        case "response":
            if let currentItem, !currentItem.href.isEmpty {
                items.append(currentItem)
            }
            currentItem = nil
        default:
            break
        }

        textBuffer = ""
        currentElement = ""
    }

    private func localName(_ elementName: String) -> String {
        elementName.split(separator: ":").last.map(String.init) ?? elementName
    }

    private func pathFromHref(_ href: String, baseURL: URL) -> String {
        // Alcuni server restituiscono href assoluti, altri solo path.
        if let url = URL(string: href), let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            return WebDAVPath.normalized(components.percentEncodedPath.removingPercentEncoding ?? components.path)
        }

        return WebDAVPath.normalized(href)
    }

    private func comparablePath(_ path: String) -> String {
        let normalized = WebDAVPath.normalized(path)
        guard normalized != "/" else { return "/" }
        return normalized.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

enum HTTPDateFormatter {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss z"
        return formatter
    }()

    static func date(from value: String) -> Date? {
        formatter.date(from: value)
    }
}
