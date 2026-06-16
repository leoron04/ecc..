import Foundation

struct ServerConfiguration: Equatable, Codable {
    let ipAddress: String
    let password: String

    var username: String { "ud" }

    var baseURL: URL {
        URL(string: "http://\(ipAddress):8087")!
    }

    var authorizationHeader: String {
        let token = "\(username):\(password)"
        let encoded = Data(token.utf8).base64EncodedString()
        return "Basic \(encoded)"
    }

    static func parse(onboardingCode: String) throws -> ServerConfiguration {
        let parts = onboardingCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)

        guard parts.count == 2 else {
            throw UnifiedDriveError.invalidOnboardingCode
        }

        let ip = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
        let password = String(parts[1])

        guard !ip.isEmpty, !password.isEmpty else {
            throw UnifiedDriveError.invalidOnboardingCode
        }

        return ServerConfiguration(ipAddress: ip, password: password)
    }
}

