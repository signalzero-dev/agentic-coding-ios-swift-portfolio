import Foundation
import Testing
@testable import NetworkKit

@Suite(.serialized)
struct URLSessionAPIClientTests {
    @Test
    func returnsDataAndHTTPResponseOn200() async throws {
        URLProtocolStub.reset()
        let stubURL = try #require(URL(string: "https://api.example.com/ping"))
        let payload = Data("{\"ok\":true}".utf8)
        let httpResponse = try #require(HTTPURLResponse(
            url: stubURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        URLProtocolStub.set(.init(data: payload, response: httpResponse, error: nil))

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        let base = try #require(URL(string: "https://api.example.com"))
        let client = URLSessionAPIClient(baseURL: base, session: session)
        let endpoint = Endpoint(path: "/ping", method: .get)

        let (data, response) = try await client.send(endpoint)

        #expect(data == payload)
        #expect(response.statusCode == 200)
    }

    @Test
    func appliesDefaultHeadersAndEndpointOverrides() async throws {
        URLProtocolStub.reset()
        let stubURL = try #require(URL(string: "https://api.example.com/ping"))
        let httpResponse = try #require(HTTPURLResponse(
            url: stubURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        URLProtocolStub.set(.init(data: Data(), response: httpResponse, error: nil))

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        let base = try #require(URL(string: "https://api.example.com"))
        let client = URLSessionAPIClient(
            baseURL: base,
            session: session,
            defaultHeaders: [
                "Authorization": "Bearer default",
                "Accept": "application/json"
            ]
        )
        let endpoint = Endpoint(
            path: "/ping",
            method: .get,
            headers: ["Authorization": "Bearer endpoint"]
        )

        _ = try await client.send(endpoint)

        let captured = try #require(URLProtocolStub.lastRequest())
        #expect(captured.value(forHTTPHeaderField: "Authorization") == "Bearer endpoint")
        #expect(captured.value(forHTTPHeaderField: "Accept") == "application/json")
    }
}
