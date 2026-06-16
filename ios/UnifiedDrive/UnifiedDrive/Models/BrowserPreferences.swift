import Foundation

enum BrowserLayoutMode: String, CaseIterable, Identifiable {
    case grid
    case list

    var id: String { rawValue }

    var title: String {
        switch self {
        case .grid:
            return "Griglia"
        case .list:
            return "Lista"
        }
    }

    var systemImage: String {
        switch self {
        case .grid:
            return "square.grid.2x2"
        case .list:
            return "list.bullet"
        }
    }
}

enum BrowserSortMode: String, CaseIterable, Identifiable {
    case name
    case kind
    case modified
    case size

    var id: String { rawValue }

    var title: String {
        switch self {
        case .name:
            return "Nome"
        case .kind:
            return "Tipo"
        case .modified:
            return "Data"
        case .size:
            return "Dimensione"
        }
    }
}

struct BrowserMetrics: Equatable {
    var lastRefresh: Date?
    var lastLatency: TimeInterval?

    var latencyText: String {
        guard let lastLatency else { return "n/d" }
        return "\(Int(lastLatency * 1000)) ms"
    }

    var refreshText: String {
        guard let lastRefresh else { return "mai" }
        return lastRefresh.formatted(date: .omitted, time: .shortened)
    }
}
