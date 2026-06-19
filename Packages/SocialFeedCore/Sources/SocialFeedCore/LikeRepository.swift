/// Abstraction over liking/unliking a post. The concrete implementation
/// (SocialFeedFirebase) writes to Firestore; tests inject a mock.
public protocol LikeRepository: Sendable {
    /// Set the current user's like state for a post.
    func setLike(postID: String, liked: Bool) async throws
}
