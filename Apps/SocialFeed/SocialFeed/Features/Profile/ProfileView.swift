import SwiftUI
import SocialFeedCore

/// The signed-in user's profile: their posts, plus sign-out.
struct ProfileView: View {
    @State private var viewModel: ProfileViewModel
    private let onSignOut: @MainActor () async -> Void

    init(
        user: User,
        container: RootContainer,
        onSignOut: @escaping @MainActor () async -> Void
    ) {
        _viewModel = State(initialValue: container.makeProfileViewModel(user: user))
        self.onSignOut = onSignOut
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(viewModel.user.displayName)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Sign Out", role: .destructive) {
                            Task { await onSignOut() }
                        }
                    }
                }
                .task { viewModel.start() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let posts) where posts.isEmpty:
            ContentUnavailableView("No posts yet", systemImage: "square.stack")
        case .loaded(let posts):
            List(posts) { post in
                PostRow(post: post) { /* likes are toggled from the feed */ }
            }
            .listStyle(.plain)
        case .error:
            ContentUnavailableView(
                "Couldn't load posts",
                systemImage: "exclamationmark.triangle"
            )
        }
    }
}
