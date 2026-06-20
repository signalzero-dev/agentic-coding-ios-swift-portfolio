import SocialFeedCore

/// Test double for `ProfileRepository`. Records the requested user ID and lets the
/// test drive the post stream via `emit(_:)` / `fail(_:)`.
final class MockProfileRepository: ProfileRepository, @unchecked Sendable {
    private(set) var requestedUserID: String?
    private let stream: AsyncThrowingStream<[Post], Error>
    private let continuation: AsyncThrowingStream<[Post], Error>.Continuation

    init() {
        (stream, continuation) = AsyncThrowingStream.makeStream(of: [Post].self)
    }

    func userPostsStream(userID: String) -> AsyncThrowingStream<[Post], Error> {
        requestedUserID = userID
        return stream
    }

    func emit(_ posts: [Post]) { continuation.yield(posts) }
    func fail(_ error: Error) { continuation.finish(throwing: error) }
}
