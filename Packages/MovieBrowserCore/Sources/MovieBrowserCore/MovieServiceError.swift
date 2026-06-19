import Foundation

public enum MovieServiceError: Error, Sendable {
    case notFound
    case rateLimited
    case server(Int)
    case decoding(any Error)
    case transport(any Error)
}
