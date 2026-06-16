import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var session: AppSessionViewModel

    var body: some View {
        Group {
            if let client = session.client {
                NavigationStack {
                    FileBrowserView(path: "/", client: client, cache: session.cache)
                }
            } else {
                OnboardingView()
            }
        }
    }
}

