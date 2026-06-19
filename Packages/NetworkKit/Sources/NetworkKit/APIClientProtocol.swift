import Foundation

public protocol APIClientProtocol: Sendable {
    func send(_ endpoint: Endpoint) async throws -> (Data, HTTPURLResponse)
}
