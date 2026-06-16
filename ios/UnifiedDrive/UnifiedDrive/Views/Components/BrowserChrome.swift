import SwiftUI

struct BrowserHeroView: View {
    let title: String
    let path: String
    let isOnline: Bool
    let metrics: BrowserMetrics
    let itemCount: Int
    let cachedCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                    Text(path == "/" ? "Root WebDAV su Tailscale" : path)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                }

                Spacer()

                StatusCapsule(isOnline: isOnline)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                AdaptiveGlassGroup(spacing: 14) {
                    HStack(spacing: 10) {
                        MetricPill(title: "Elementi", value: "\(itemCount)", systemImage: "square.stack.3d.up", tint: .cyan)
                        MetricPill(title: "Latenza", value: metrics.latencyText, systemImage: "speedometer", tint: isOnline ? .green : .orange)
                        MetricPill(title: "Cache", value: "\(cachedCount)", systemImage: "internaldrive", tint: .indigo)
                        MetricPill(title: "Refresh", value: metrics.refreshText, systemImage: "clock.arrow.circlepath", tint: .mint)
                    }
                }
            }
        }
        .padding(18)
        .adaptiveGlass(cornerRadius: 28, tint: .white.opacity(0.08))
    }
}

struct StatusCapsule: View {
    let isOnline: Bool

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(isOnline ? Color.green : Color.orange)
                .frame(width: 9, height: 9)
            Text(isOnline ? "Online" : "Offline")
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .adaptiveGlass(cornerRadius: 18, tint: (isOnline ? Color.green : Color.orange).opacity(0.18))
    }
}

struct BrowserControlBar: View {
    @Binding var layoutMode: BrowserLayoutMode
    @Binding var sortMode: BrowserSortMode
    let createFolder: () -> Void
    let uploadFile: () -> Void

    var body: some View {
        AdaptiveGlassGroup(spacing: 12) {
            ViewThatFits {
                horizontalControls
                VStack(spacing: 10) {
                    horizontalPrimaryControls
                    HStack(spacing: 12) {
                        sortMenu
                        Spacer()
                        actionButtons
                    }
                }
            }
            .padding(10)
            .adaptiveGlass(cornerRadius: 20)
        }
    }

    private var horizontalControls: some View {
        HStack(spacing: 12) {
            horizontalPrimaryControls
            sortMenu
            Spacer()
            actionButtons
        }
    }

    private var horizontalPrimaryControls: some View {
        Picker("Vista", selection: $layoutMode) {
            ForEach(BrowserLayoutMode.allCases) { mode in
                Image(systemName: mode.systemImage)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 150)
    }

    private var sortMenu: some View {
        Menu {
            Picker("Ordina", selection: $sortMode) {
                ForEach(BrowserSortMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
        } label: {
            Label(sortMode.title, systemImage: "arrow.up.arrow.down")
                .font(.subheadline.weight(.semibold))
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: createFolder) {
                Image(systemName: "folder.badge.plus")
            }
            .accessibilityLabel("Crea cartella")

            Button(action: uploadFile) {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Carica file")
        }
    }
}
