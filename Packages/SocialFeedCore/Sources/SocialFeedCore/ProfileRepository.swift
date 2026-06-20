/// Streams a single user's posts (for the profile screen). The concrete
/// implementation (SocialFeedFirebase) wraps a filtered Firestore listener.
public protocol ProfileRepository: Sendable {
    func userPostsStream(userID: String) -> AsyncThrowingStream<[Post], Error>
}
