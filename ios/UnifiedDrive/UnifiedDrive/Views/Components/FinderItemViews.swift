import SwiftUI

struct FinderTileView: View {
    let item: WebDAVItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: item.type.systemImage)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 48, height: 48)
                    .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Spacer()

                if item.isDirectory {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                FinderMetadataLine(item: item)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
        .adaptiveGlass(cornerRadius: 20, tint: iconColor.opacity(0.08), isInteractive: true)
    }

    private var iconColor: Color {
        switch item.type {
        case .folder:
            return .blue
        case .image:
            return .pink
        case .pdf:
            return .red
        case .video:
            return .purple
        case .audio:
            return .green
        case .document:
            return .teal
        case .other:
            return .secondary
        }
    }
}

struct FinderListRowView: View {
    let item: WebDAVItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.type.systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                FinderMetadataLine(item: item)
            }

            Spacer()

            if item.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .adaptiveGlass(cornerRadius: 16, tint: iconColor.opacity(0.06), isInteractive: true)
    }

    private var iconColor: Color {
        item.isDirectory ? .blue : .secondary
    }
}

private struct FinderMetadataLine: View {
    let item: WebDAVItem

    var body: some View {
        HStack(spacing: 7) {
            if item.isDirectory {
                Text("Cartella")
            } else if !item.displaySize.isEmpty {
                Text(item.displaySize)
            } else {
                Text("File")
            }

            if let lastModified = item.lastModified {
                Text("·")
                Text(lastModified, style: .date)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
}

