import Foundation
import Observation

/// Drives the real-time feed screen. Consumes `FeedRepository.feedStream()` and
/// publishes a `LoadState`. Real-time updates stay in-place (`.loaded → .loaded`)
/// so the list never unmounts mid-update.
@MainActor
@Observable
public final class FeedViewModel {
    public private(set) var state: LoadState<[Post], FeedError> = .idle

    private let feedRepository: any FeedRepository
    private let likeRepository: any LikeRepository
    private var streamTask: Task<Void, Never>?

    public init(
        feedRepository: any FeedRepository,
        likeRepository: any LikeRepository
    ) {
        self.feedRepository = feedRepository
        self.likeRepository = likeRepository
    }

    /// Begins consuming the feed stream. Idempotent — a second call while already
    /// streaming is a no-op.
    public func start() {
        guard streamTask == nil else { return }
        state = .loading
        streamTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await posts in self.feedRepository.feedStream() {
                    self.state = .loaded(posts)
                }
            } catch is CancellationError {
                // Expected when stop() cancels the stream; leave state as-is.
            } catch let error as FeedError {
                self.state = .error(error)
            } catch {
                self.state = .error(.unknown)
            }
        }
    }

    /// Stops consuming the feed stream, awaiting the cancelled task so that no
    /// further state updates can land after this returns.
    public func stop() async {
        streamTask?.cancel()
        await streamTask?.value
        streamTask = nil
    }

    /// Toggle the like on a post: update the local list immediately (optimistic),
    /// persist via the repository, and roll back if that fails. The feed stream
    /// will later emit the authoritative state and supersede the local copy.
    public func toggleLike(_ post: Post) async {
        guard case .loaded(var posts) = state,
              let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        let original = posts[index]
        let optimistic = original.togglingLike()
        posts[index] = optimistic
        state = .loaded(posts)

        do {
            try await likeRepository.setLike(postID: post.id, liked: optimistic.likedByCurrentUser)
        } catch {
            rollback(postID: post.id, to: original)
        }
    }

    private func rollback(postID: String, to original: Post) {
        guard case .loaded(var posts) = state,
              let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index] = original
        state = .loaded(posts)
    }
}
