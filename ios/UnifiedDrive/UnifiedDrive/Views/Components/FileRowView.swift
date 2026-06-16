import SwiftUI

struct FileRowView: View {
    let item: WebDAVItem
    var isCached = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.type.systemImage)
                .font(.title3)
                .foregroundStyle(item.isDirectory ? .blue : .secondary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    if !item.displaySize.isEmpty {
                        Text(item.displaySize)
                    }

                    if let lastModified = item.lastModified {
                        Text(lastModified, style: .date)
                    }

                    if isCached {
                        Label("Cache", systemImage: "internaldrive")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}

