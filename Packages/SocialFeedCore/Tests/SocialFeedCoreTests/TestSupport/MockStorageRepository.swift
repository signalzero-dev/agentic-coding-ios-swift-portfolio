import Foundation
import SocialFeedCore

/// Test double for `StorageRepository`. Counts uploads and returns a stubbed result.
final class MockStorageRepository: StorageRepository, @unchecked Sendable {
    private(set) var uploadCount = 0
    /// Defaults to failure so tests that exercise image upload must opt in explicitly.
    var result: Result<URL, Error> = .failure(NotConfigured.noResult)

    func uploadImage(_ data: Data) async throws -> URL {
        uploadCount += 1
        return try result.get()
    }

    enum NotConfigured: Error { case noResult }
}
