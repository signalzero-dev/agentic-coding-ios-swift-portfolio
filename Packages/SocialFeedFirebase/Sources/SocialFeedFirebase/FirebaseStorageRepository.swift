@preconcurrency import FirebaseStorage
@preconcurrency import FirebaseAuth
import Foundation
import SocialFeedCore

/// Firebase-backed `StorageRepository`. Uploads image data under
/// `post_images/{uid}/{uuid}.jpg` and returns its download URL.
public final class FirebaseStorageRepository: StorageRepository, @unchecked Sendable {
    public init() {}

    public func uploadImage(_ data: Data) async throws -> URL {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirebaseRepositoryError.notAuthenticated
        }
        let ref = Storage.storage().reference()
            .child("post_images/\(uid)/\(UUID().uuidString).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(data, metadata: metadata)
        return try await ref.downloadURL()
    }
}
