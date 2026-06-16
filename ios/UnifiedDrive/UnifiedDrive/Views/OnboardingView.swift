import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @State private var code = ""

    var body: some View {
        NavigationStack {
            ZStack {
                UnifiedBackground()

                ScrollView {
                    VStack(spacing: 22) {
                        hero
                        connectionCard
                        securityStrip
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 34)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private var hero: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.14))
                    .frame(width: 92, height: 92)
                Image(systemName: "externaldrive.connected.to.line.below")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .adaptiveGlass(cornerRadius: 46, tint: .cyan.opacity(0.16))

            VStack(spacing: 8) {
                Text("UnifiedDrive")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Text("Il tuo filesystem WebDAV su Tailscale, con cache offline e anteprime native iOS.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.74))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
        }
    }

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Codice connessione")
                    .font(.headline)
                Text("Formato: IP|password. L'utente WebDAV e sempre ud.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextField("100.101.102.103|abc123", text: $code)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .font(.system(.body, design: .monospaced))
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            if let error = session.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                Task {
                    await session.connect(using: code)
                }
            } label: {
                HStack {
                    Spacer()
                    if session.isConnecting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(session.isConnecting ? "Verifica WebDAV" : "Connetti")
                        .font(.headline)
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.vertical, 14)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(session.isConnecting || code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(session.isConnecting || code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
        }
        .padding(18)
        .adaptiveGlass(cornerRadius: 28, tint: .white.opacity(0.10))
    }

    private var securityStrip: some View {
        ViewThatFits {
            HStack(spacing: 10) {
                Label("Keychain", systemImage: "key.fill")
                Label("Tailscale", systemImage: "lock.shield.fill")
                Label("WebDAV", systemImage: "server.rack")
            }
            VStack(spacing: 8) {
                Label("Keychain", systemImage: "key.fill")
                Label("Tailscale", systemImage: "lock.shield.fill")
                Label("WebDAV", systemImage: "server.rack")
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white.opacity(0.88))
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .adaptiveGlass(cornerRadius: 20)
    }
}
