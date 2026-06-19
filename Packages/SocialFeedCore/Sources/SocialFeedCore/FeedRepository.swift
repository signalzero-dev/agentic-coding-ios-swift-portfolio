/// Abstraction over the real-time feed source. The concrete implementation
/// (SocialFeedFirebase) wraps a Firestore snapshot listener; tests inject a mock.
/// Returning an `AsyncStream` keeps the reactive flow Combine-free.
public protocol FeedRepository: Sendable {
    /// A live stream of the feed. Each element is the full current list of posts;
    /// the stream emits again whenever the underlying data changes, and terminates
    /// by throwing if the listener fails (e.g. permission denied, network loss).
    func feedStream() -> AsyncThrowingStream<[Post], Error>
}
