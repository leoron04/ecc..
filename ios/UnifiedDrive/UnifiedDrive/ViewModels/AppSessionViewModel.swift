import Foundation

@MainActor
final class AppSessionViewModel: ObservableObject {
    @Published private(set) var configuration: ServerConfiguration?
    @Published private(set) var client: WebDAVClient?
    @Published var isConnecting = false
    @Published var isOnline = false
    @Published var errorMessage: String?

    let cache = DiskCache()
    private let keychain = KeychainService()

    init() {
        do {
            if let configuration = try keychain.loadConfiguration() {
                install(configuration: configuration)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func connect(using code: String) async {
        isConnecting = true
        errorMessage = nil
        defer { isConnecting = false }

        do {
            let configuration = try ServerConfiguration.parse(onboardingCode: code)
            let webDAVClient = WebDAVClient(configuration: configuration)
            try await webDAVClient.verifyRoot()
            try keychain.save(configuration: configuration)
            install(configuration: configuration)
            isOnline = true
        } catch {
            isOnline = false
            errorMessage = error.localizedDescription
        }
    }

    func setOnline(_ value: Bool) {
        isOnline = value
    }

    func disconnect() {
        keychain.clear()
        configuration = nil
        client = nil
        isOnline = false
    }

    private func install(configuration: ServerConfiguration) {
        self.configuration = configuration
        self.client = WebDAVClient(configuration: configuration)
    }
}

