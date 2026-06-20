import SwiftUI
import SocialFeedCore

/// Real-time feed. Owns a `FeedViewModel` and renders its `LoadState`.
struct FeedView: View {
    @State private var viewModel: FeedViewModel
    private let onSignOut: @MainActor () async -> Void

    init(container: RootContainer, onSignOut: @escaping @MainActor () async -> Void) {
        _viewModel = State(initialValue: container.makeFeedViewModel())
        self.onSignOut = onSignOut
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Feed")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Sign Out") { Task { await onSignOut() } }
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
                PostRow(post: post) {
                    Task { await viewModel.toggleLike(post) }
                }
            }
            .listStyle(.plain)
        case .error(let error):
            ContentUnavailableView(
                "Couldn't load the feed",
                systemImage: "exclamationmark.triangle",
                description: Text(message(for: error))
            )
        }
    }

    private func message(for error: FeedError) -> String {
        switch error {
        case .permissionDenied: "You don't have permission to view this feed."
        case .unavailable: "The feed is temporarily unavailable."
        case .unknown: "Something went wrong."
        }
    }
}
