/// Typed errors from building a link preview.
public enum LinkPreviewError: Error, Equatable, Sendable {
    /// The page could not be fetched.
    case fetchFailed
    /// The page had no usable Open Graph metadata.
    case noMetadata
}
