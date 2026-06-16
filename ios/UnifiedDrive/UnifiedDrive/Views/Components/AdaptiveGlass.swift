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
        Group {
            #if compiler(>=6.2)
            if #available(iOS 26.0, *) {
                content
                    .glassEffect(
                        glass,
                        in: .rect(cornerRadius: cornerRadius)
                    )
            } else {
                fallback(content)
            }
            #else
            fallback(content)
            #endif
        }
    }

    #if compiler(>=6.2)
    @available(iOS 26.0, *)
    private var glass: Glass {
        let base = tint.map { Glass.regular.tint($0) } ?? .regular
        return isInteractive ? base.interactive() : base
    }
    #endif

    private func fallback(_ content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.16), lineWidth: 1)
            }
    }
}

extension View {
    func adaptiveGlass(cornerRadius: CGFloat = 22, tint: Color? = nil, isInteractive: Bool = false) -> some View {
        modifier(AdaptiveGlassModifier(cornerRadius: cornerRadius, tint: tint, isInteractive: isInteractive))
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
        Group {
            #if compiler(>=6.2)
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: spacing) {
                    content()
                }
            } else {
                content()
            }
            #else
            content()
            #endif
        }
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
