import Foundation
import Observation

/// Drives the compose screen: validates the text, uploads an optional image, then
/// creates the post. `didPost` flips true on success so the view can dismiss.
@MainActor
@Observable
public final class ComposeViewModel {
    public var text: String = ""
    public private(set) var submitState: LoadState<Void, ComposeError> = .idle
    public private(set) var didPost: Bool = false

    private let postRepository: any PostRepository
    private let storageRepository: any StorageRepository

    public init(
        postRepository: any PostRepository,
        storageRepository: any StorageRepository
    ) {
        self.postRepository = postRepository
        self.storageRepository = storageRepository
    }

    public func submit(imageData: Data?) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            submitState = .error(.emptyText)
            return
        }
        submitState = .loading

        var imageURL: URL?
        if let imageData {
            do {
                imageURL = try await storageRepository.uploadImage(imageData)
            } catch {
                submitState = .error(.uploadFailed)
                return
            }
        }

        do {
            try await postRepository.create(text: trimmed, imageURL: imageURL)
        } catch {
            submitState = .error(.postFailed)
            return
        }

        submitState = .loaded(())
        didPost = true
    }
}
