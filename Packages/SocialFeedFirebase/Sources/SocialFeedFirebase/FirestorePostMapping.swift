@preconcurrency import FirebaseFirestore
import Foundation
import SocialFeedCore

/// Shared Firestore ↔ domain mapping for posts, used by the feed and profile repos.
enum FirestorePostMapping {
    static func post(from doc: QueryDocumentSnapshot, currentUserID: String?) -> Post? {
        let data = doc.data()
        guard let authorID = data["authorID"] as? String,
              let authorName = data["authorName"] as? String,
              let text = data["text"] as? String,
              let createdAt = data["createdAt"] as? Timestamp else {
            return nil
        }
        let likedBy = data["likedBy"] as? [String] ?? []
        return Post(
            id: doc.documentID,
            authorID: authorID,
            authorName: authorName,
            text: text,
            imageURL: (data["imageURL"] as? String).flatMap { URL(string: $0) },
            createdAt: createdAt.dateValue(),
            likeCount: data["likeCount"] as? Int ?? likedBy.count,
            likedByCurrentUser: currentUserID.map(likedBy.contains) ?? false
        )
    }

    static func feedError(from error: Error) -> FeedError {
        switch FirestoreErrorCode.Code(rawValue: (error as NSError).code) {
        case .permissionDenied: return .permissionDenied
        case .unavailable: return .unavailable
        default: return .unknown
        }
    }
}
