@preconcurrency import FirebaseFirestore
@preconcurrency import FirebaseAuth
import Foundation
import SocialFeedCore

/// Firebase-backed `PostRepository`. Creates a `posts` document authored by the
/// signed-in user, with a server timestamp and zeroed like fields.
public final class FirestorePostRepository: PostRepository, @unchecked Sendable {
    private let collectionPath: String

    public init(collectionPath: String = "posts") {
        self.collectionPath = collectionPath
    }

    public func create(text: String, imageURL: URL?) async throws {
        guard let user = Auth.auth().currentUser else {
            throw FirebaseRepositoryError.notAuthenticated
        }
        var data: [String: Any] = [
            "authorID": user.uid,
            "authorName": user.displayName ?? user.email ?? "User",
            "text": text,
            "createdAt": FieldValue.serverTimestamp(),
            "likeCount": 0,
            "likedBy": [String]()
        ]
        if let imageURL {
            data["imageURL"] = imageURL.absoluteString
        }
        try await Firestore.firestore().collection(collectionPath).document().setData(data)
    }
}
