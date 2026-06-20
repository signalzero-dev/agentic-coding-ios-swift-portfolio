import SwiftUI
import SocialFeedCore

/// Signed-in shell: Feed and Profile tabs.
struct MainTabView: View {
    let container: RootContainer
    let user: User
    let onSignOut: @MainActor () async -> Void

    var body: some View {
        TabView {
            FeedView(container: container)
                .tabItem { Label("Feed", systemImage: "house") }
            ProfileView(user: user, container: container, onSignOut: onSignOut)
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}
