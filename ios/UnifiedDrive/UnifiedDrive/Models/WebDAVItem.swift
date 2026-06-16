import Foundation
import UniformTypeIdentifiers

struct WebDAVItem: Identifiable, Hashable, Codable {
    let path: String
    let name: String
    let isDirectory: Bool
    let size: Int64?
    let lastModified: Date?
    let contentType: String?

    var id: String { path }

    var fileExtension: String {
        URL(fileURLWithPath: name).pathExtension.lowercased()
    }

    var displaySize: String {
        guard !isDirectory, let size else { return "" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var type: FileDisplayType {
        guard !isDirectory else { return .folder }

        if let contentType, let uniformType = UTType(mimeType: contentType) {
            if uniformType.conforms(to: .image) { return .image }
            if uniformType.conforms(to: .pdf) { return .pdf }
            if uniformType.conforms(to: .movie) { return .video }
            if uniformType.conforms(to: .audio) { return .audio }
        }

        switch fileExtension {
        case "jpg", "jpeg", "png", "gif", "heic", "webp", "tiff":
            return .image
        case "pdf":
            return .pdf
        case "mov", "mp4", "m4v", "avi", "mkv":
            return .video
        case "mp3", "m4a", "wav", "aac", "flac":
            return .audio
        case "txt", "md", "json", "csv", "rtf":
            return .document
        default:
            return .other
        }
    }
}

enum FileDisplayType: String, Codable {
    case folder
    case image
    case pdf
    case video
    case audio
    case document
    case other

    var systemImage: String {
        switch self {
        case .folder:
            return "folder.fill"
        case .image:
            return "photo"
        case .pdf:
            return "doc.richtext"
        case .video:
            return "play.rectangle"
        case .audio:
            return "waveform"
        case .document:
            return "doc.text"
        case .other:
            return "doc"
        }
    }
}

