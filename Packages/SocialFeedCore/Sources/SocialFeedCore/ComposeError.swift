/// Typed errors from composing a post.
public enum ComposeError: Error, Equatable, Sendable {
    case emptyText
    case uploadFailed
    case postFailed
}
