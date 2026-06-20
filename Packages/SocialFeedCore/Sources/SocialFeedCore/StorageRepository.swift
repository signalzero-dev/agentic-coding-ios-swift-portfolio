import Foundation

/// Uploads image data and returns its download URL. The concrete implementation
/// (SocialFeedFirebase) uses Firebase Storage; tests inject a mock.
public protocol StorageRepository: Sendable {
    func uploadImage(_ data: Data) async throws -> URL
}
