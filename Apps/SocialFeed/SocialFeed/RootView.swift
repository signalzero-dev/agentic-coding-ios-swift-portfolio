import SwiftUI
import SocialFeedCore

/// Switches between the auth screen and the main tabs based on the session, which
/// is driven by the auth-state stream.
struct RootView: View {
    @State private var authViewModel: AuthViewModel
    private let container: RootContainer

    init(container: RootContainer) {
        self.container = container
        _authViewModel = State(initialValue: container.makeAuthViewModel())
    }

    var body: some View {
        Group {
            if let user = authViewModel.session {
                MainTabView(container: container, user: user) {
                    await authViewModel.signOut()
                }
            } else {
                AuthView(viewModel: authViewModel)
            }
        }
        .task { authViewModel.start() }
    }
}
