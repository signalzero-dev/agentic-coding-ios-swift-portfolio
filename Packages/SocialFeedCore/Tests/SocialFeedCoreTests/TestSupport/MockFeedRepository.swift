import SocialFeedCore

/// Test double for `FeedRepository`. Hands out a single `AsyncStream` whose
/// continuation the test drives via `emit(_:)` / `finish()`.
final class MockFeedRepository: FeedRepository, @unchecked Sendable {
    private let stream: AsyncThrowingStream<[Post], Error>
    private let continuation: AsyncThrowingStream<[Post], Error>.Continuation

    init() {
        (stream, continuation) = AsyncThrowingStream.makeStream(of: [Post].self)
    }

    func feedStream() -> AsyncThrowingStream<[Post], Error> { stream }

    /// Push a new feed snapshot to the consumer.
    func emit(_ posts: [Post]) { continuation.yield(posts) }

    /// End the stream cleanly.
    func finish() { continuation.finish() }

    /// End the stream with a failure.
    func fail(_ error: Error) { continuation.finish(throwing: error) }
}
