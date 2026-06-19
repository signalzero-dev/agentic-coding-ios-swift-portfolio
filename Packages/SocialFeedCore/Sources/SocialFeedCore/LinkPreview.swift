import Foundation

/// Open Graph metadata for a URL, shown as a rich link card in the feed/compose UI.
public struct LinkPreview: Equatable, Sendable {
    public let url: URL
    public let title: String?
    public let description: String?
    public let imageURL: URL?

    public init(url: URL, title: String?, description: String?, imageURL: URL?) {
        self.url = url
        self.title = title
        self.description = description
        self.imageURL = imageURL
    }
}
