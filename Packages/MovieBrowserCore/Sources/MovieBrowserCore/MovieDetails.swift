import Foundation

public struct MovieDetails: Decodable, Sendable {
    public let id: Int
    public let title: String
    public let overview: String
    public let posterPath: String
    public let runtime: Int
    public let tagline: String
}
