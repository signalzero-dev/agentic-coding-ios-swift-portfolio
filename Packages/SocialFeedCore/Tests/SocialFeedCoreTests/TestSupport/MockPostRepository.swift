import Foundation
import SocialFeedCore

/// Test double for `PostRepository`. Records successful creations; can be told to fail.
final class MockPostRepository: PostRepository, @unchecked Sendable {
    private(set) var created: [(text: String, imageURL: URL?)] = []
    var error: Error?

    func create(text: String, imageURL: URL?) async throws {
        if let error { throw error }
        created.append((text, imageURL))
    }
}
