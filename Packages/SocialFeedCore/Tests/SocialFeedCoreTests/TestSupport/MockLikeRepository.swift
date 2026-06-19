import SocialFeedCore

/// Test double for `LikeRepository`. Records calls and can be told to fail.
final class MockLikeRepository: LikeRepository, @unchecked Sendable {
    private(set) var calls: [(postID: String, liked: Bool)] = []
    var error: Error?

    func setLike(postID: String, liked: Bool) async throws {
        calls.append((postID, liked))
        if let error { throw error }
    }
}
