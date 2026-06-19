import Foundation

public struct MoviePage: Decodable, Sendable {
    public let page: Int
    public let results: [Movie]
    public let totalPages: Int
    public let totalResults: Int
}
