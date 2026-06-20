import SwiftUI
import SocialFeedCore

/// Switches between the auth screen and the feed based on the session, which is
/// driven by the auth-state stream.
struct RootView: View {
    @State private var authViewModel: AuthViewModel
    private let container: RootContainer

    init(container: RootContainer) {
        self.container = container
        _authViewModel = State(initialValue: container.makeAuthViewModel())
    }

    var body: some View {
        Group {
            if authViewModel.session == nil {
                AuthView(viewModel: authViewModel)
            } else {
                FeedView(container: container) {
                    await authViewModel.signOut()
                }
            }
        }
        .task { authViewModel.start() }
    }
}
