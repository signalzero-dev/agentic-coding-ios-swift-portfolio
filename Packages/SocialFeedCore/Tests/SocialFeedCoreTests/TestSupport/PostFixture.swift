import Foundation
import SocialFeedCore

extension Post {
    /// Concrete sample post for tests, with sensible defaults.
    static func sample(
        id: String,
        authorName: String = "Ada",
        text: String = "hello"
    ) -> Post {
        Post(
            id: id,
            authorID: "author-\(id)",
            authorName: authorName,
            text: text,
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }
}
