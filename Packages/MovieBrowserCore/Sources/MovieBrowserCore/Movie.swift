import Foundation

public struct Movie: Decodable, Sendable {
    public let id: Int
    public let title: String
    public let overview: String
    public let posterPath: String?
}
