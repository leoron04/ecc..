import SwiftUI

@main
struct UnifiedDriveApp: App {
    @StateObject private var session = AppSessionViewModel()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(session)
        }
    }
}

