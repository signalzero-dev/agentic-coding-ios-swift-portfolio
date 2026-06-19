import Foundation

/// A feed post. Pure domain model — no Firebase types; mapping from Firestore
/// happens in the (later) SocialFeedFirebase package.
public struct Post: Identifiable, Equatable, Sendable {
    public let id: String
    public let authorID: String
    public let authorName: String
    public let text: String
    public let imageURL: URL?
    public let createdAt: Date
    public let likeCount: Int
    public let likedByCurrentUser: Bool

    public init(
        id: String,
        authorID: String,
        authorName: String,
        text: String,
        imageURL: URL? = nil,
        createdAt: Date,
        likeCount: Int = 0,
        likedByCurrentUser: Bool = false
    ) {
        self.id = id
        self.authorID = authorID
        self.authorName = authorName
        self.text = text
        self.imageURL = imageURL
        self.createdAt = createdAt
        self.likeCount = likeCount
        self.likedByCurrentUser = likedByCurrentUser
    }

    /// A copy with the current user's like toggled and `likeCount` adjusted by one.
    /// Used for optimistic UI updates.
    public func togglingLike() -> Post {
        let nowLiked = !likedByCurrentUser
        return Post(
            id: id,
            authorID: authorID,
            authorName: authorName,
            text: text,
            imageURL: imageURL,
            createdAt: createdAt,
            likeCount: likeCount + (nowLiked ? 1 : -1),
            likedByCurrentUser: nowLiked
        )
    }
}
