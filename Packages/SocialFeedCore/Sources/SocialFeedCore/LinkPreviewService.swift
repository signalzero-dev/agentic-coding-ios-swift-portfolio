import Foundation

public protocol LinkPreviewProviding: Sendable {
    func preview(for url: URL) async throws -> LinkPreview
}

/// Builds a `LinkPreview` by loading a page's HTML and parsing its Open Graph
/// (`og:*`) meta tags. Transport is injected via `HTMLLoading`; the parsing is
/// the testable core.
public struct LinkPreviewService: LinkPreviewProviding {
    private let loader: any HTMLLoading

    public init(loader: any HTMLLoading) {
        self.loader = loader
    }

    public func preview(for url: URL) async throws -> LinkPreview {
        let data: Data
        do {
            data = try await loader.loadHTML(from: url)
        } catch {
            throw LinkPreviewError.fetchFailed
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw LinkPreviewError.noMetadata
        }

        let tags = OpenGraph.parse(html)
        guard !tags.isEmpty else { throw LinkPreviewError.noMetadata }

        return LinkPreview(
            url: url,
            title: tags["og:title"],
            description: tags["og:description"],
            imageURL: tags["og:image"].flatMap { URL(string: $0) }
        )
    }
}

/// Minimal Open Graph extractor: pulls `og:*` properties from `<meta>` tags.
/// Tolerates attribute order (`property`/`content`), single or double quotes,
/// and the `name=` spelling some sites use instead of `property=`.
enum OpenGraph {
    static func parse(_ html: String) -> [String: String] {
        // Built locally: a static stored Regex isn't Sendable under Swift 6.
        let metaTag = /<meta\b[^>]*>/.ignoresCase()
        let propertyAttr = /property\s*=\s*["']([^"']*)["']/.ignoresCase()
        let nameAttr = /name\s*=\s*["']([^"']*)["']/.ignoresCase()
        let contentAttr = /content\s*=\s*["']([^"']*)["']/.ignoresCase()

        var result: [String: String] = [:]
        for match in html.matches(of: metaTag) {
            let tag = match.output
            let key = tag.firstMatch(of: propertyAttr)?.1 ?? tag.firstMatch(of: nameAttr)?.1
            guard let key, key.hasPrefix("og:"),
                  let content = tag.firstMatch(of: contentAttr)?.1 else { continue }
            result[String(key)] = String(content)
        }
        return result
    }
}
