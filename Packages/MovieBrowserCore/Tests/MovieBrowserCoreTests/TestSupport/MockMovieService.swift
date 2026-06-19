import Foundation
import os
@testable import MovieBrowserCore

final class MockMovieService: MovieServiceProtocol, @unchecked Sendable {
    private let lock = OSAllocatedUnfairLock()
    private var popularResult: Result<MoviePage, MovieServiceError>?
    private var popularGate: CheckedContinuation<Void, Never>?
    private var popularGateEnabled = false
    private var popularContinuation: CheckedContinuation<Void, Never>?
    private var popularPagesRequestedStorage: [Int] = []
    private var detailsResult: Result<MovieDetails, MovieServiceError>?
    private var detailsGateEnabled = false
    private var detailsContinuation: CheckedContinuation<Void, Never>?
    private var searchResult: Result<MoviePage, MovieServiceError>?
    private var searchCallCountStorage: Int = 0
    private var lastSearchQueryStorage: String?

    func stubSearch(_ result: Result<MoviePage, MovieServiceError>) {
        lock.withLock { searchResult = result }
    }

    var searchCallCount: Int {
        lock.withLock { searchCallCountStorage }
    }

    var lastSearchQuery: String? {
        lock.withLock { lastSearchQueryStorage }
    }

    var popularPagesRequested: [Int] {
        lock.withLock { popularPagesRequestedStorage }
    }

    func stubDetails(_ result: Result<MovieDetails, MovieServiceError>) {
        lock.withLock { detailsResult = result }
    }

    func enableDetailsGate() {
        lock.withLock { detailsGateEnabled = true }
    }

    func releaseDetails() {
        let continuation = lock.withLock { () -> CheckedContinuation<Void, Never>? in
            let c = detailsContinuation
            detailsContinuation = nil
            return c
        }
        continuation?.resume()
    }

    func stubPopular(_ result: Result<MoviePage, MovieServiceError>) {
        lock.withLock { popularResult = result }
    }

    /// When enabled, `popular(page:)` suspends after capturing the call until
    /// `releasePopular()` is invoked. Lets a test inspect intermediate state.
    func enablePopularGate() {
        lock.withLock { popularGateEnabled = true }
    }

    func releasePopular() {
        let continuation = lock.withLock { () -> CheckedContinuation<Void, Never>? in
            let c = popularContinuation
            popularContinuation = nil
            return c
        }
        continuation?.resume()
    }

    func popular(page: Int) async throws -> MoviePage {
        lock.withLock { popularPagesRequestedStorage.append(page) }
        if lock.withLock({ popularGateEnabled }) {
            await withCheckedContinuation { continuation in
                lock.withLock { popularContinuation = continuation }
            }
        }
        let result = lock.withLock { popularResult }
        guard let result else {
            throw MovieServiceError.transport(URLError(.unknown))
        }
        switch result {
        case .success(let page): return page
        case .failure(let error): throw error
        }
    }

    func search(query: String, page: Int) async throws -> MoviePage {
        lock.withLock {
            searchCallCountStorage += 1
            lastSearchQueryStorage = query
        }
        let result = lock.withLock { searchResult }
        guard let result else {
            throw MovieServiceError.transport(URLError(.unknown))
        }
        switch result {
        case .success(let page): return page
        case .failure(let error): throw error
        }
    }

    func details(id: Int) async throws -> MovieDetails {
        if lock.withLock({ detailsGateEnabled }) {
            await withCheckedContinuation { continuation in
                lock.withLock { detailsContinuation = continuation }
            }
        }
        let result = lock.withLock { detailsResult }
        guard let result else {
            throw MovieServiceError.transport(URLError(.unknown))
        }
        switch result {
        case .success(let details): return details
        case .failure(let error): throw error
        }
    }
}
