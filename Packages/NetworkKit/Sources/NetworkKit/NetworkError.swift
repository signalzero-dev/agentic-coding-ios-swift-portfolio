import Foundation

public enum NetworkError: Error, Sendable, Equatable {
    case invalidURL
    case invalidResponse
}
