import Foundation
import os
import NetworkKit

final class MockAPIClient: APIClientProtocol, @unchecked Sendable {
    private let lock = OSAllocatedUnfairLock()
    private var stubbedData: Data?
    private var stubbedResponse: HTTPURLResponse?
    private var stubbedError: Error?
    private var capturedEndpoint: Endpoint?

    func stub(data: Data, response: HTTPURLResponse) {
        lock.withLock {
            stubbedData = data
            stubbedResponse = response
            stubbedError = nil
        }
    }

    func stub(error: Error) {
        lock.withLock {
            stubbedError = error
            stubbedData = nil
            stubbedResponse = nil
        }
    }

    var lastEndpoint: Endpoint? {
        lock.withLock { capturedEndpoint }
    }

    func send(_ endpoint: Endpoint) async throws -> (Data, HTTPURLResponse) {
        let (data, response, error): (Data?, HTTPURLResponse?, Error?) = lock.withLock {
            capturedEndpoint = endpoint
            return (stubbedData, stubbedResponse, stubbedError)
        }
        if let error {
            throw error
        }
        guard let data, let response else {
            throw NetworkError.invalidResponse
        }
        return (data, response)
    }
}
