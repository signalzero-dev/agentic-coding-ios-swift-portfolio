import Foundation

final class URLProtocolStub: URLProtocol {
    struct Stub: @unchecked Sendable {
        let data: Data?
        let response: HTTPURLResponse?
        let error: Error?
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var current: Stub?
    nonisolated(unsafe) private static var captured: URLRequest?

    static func set(_ stub: Stub) {
        lock.lock()
        defer { lock.unlock() }
        current = stub
    }

    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        current = nil
        captured = nil
    }

    static func lastRequest() -> URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return captured
    }

    private static func currentStub() -> Stub? {
        lock.lock()
        defer { lock.unlock() }
        return current
    }

    override class func canInit(with request: URLRequest) -> Bool {
        lock.lock()
        captured = request
        lock.unlock()
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let client else { return }
        guard let stub = Self.currentStub() else {
            client.urlProtocol(self, didFailWithError: URLError(.cancelled))
            return
        }
        if let error = stub.error {
            client.urlProtocol(self, didFailWithError: error)
            return
        }
        if let response = stub.response {
            client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        if let data = stub.data {
            client.urlProtocol(self, didLoad: data)
        }
        client.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
