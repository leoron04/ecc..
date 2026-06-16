import SwiftUI

struct UnifiedBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.11, blue: 0.16),
                Color(red: 0.10, green: 0.20, blue: 0.26),
                Color(red: 0.18, green: 0.15, blue: 0.26)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct AdaptiveGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 22
    var tint: Color?
    var isInteractive = false

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(tintOverlay)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(isInteractive ? 0.24 : 0.16), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.18), radius: isInteractive ? 14 : 8, y: isInteractive ? 8 : 4)
    }

    @ViewBuilder
    private var tintOverlay: some View {
        if let tint {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(tint)
                .blendMode(.plusLighter)
        }
    }
}

struct AdaptiveGlassGroup<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder var content: () -> Content

    init(spacing: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        content()
    }
}

extension View {
    func adaptiveGlass(cornerRadius: CGFloat = 22, tint: Color? = nil, isInteractive: Bool = false) -> some View {
        modifier(AdaptiveGlassModifier(cornerRadius: cornerRadius, tint: tint, isInteractive: isInteractive))
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = .blue

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.callout.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .adaptiveGlass(cornerRadius: 16, tint: tint.opacity(0.10))
    }
}
