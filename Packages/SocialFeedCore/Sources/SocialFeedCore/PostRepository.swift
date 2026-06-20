import Foundation

/// Creates new posts. The concrete implementation (SocialFeedFirebase) writes to
/// Firestore (author derived from the signed-in user); tests inject a mock.
public protocol PostRepository: Sendable {
    func create(text: String, imageURL: URL?) async throws
}
