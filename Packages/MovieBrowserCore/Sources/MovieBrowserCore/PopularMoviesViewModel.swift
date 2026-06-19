import Foundation
import Observation

@MainActor
@Observable
public final class PopularMoviesViewModel {
    public private(set) var state: LoadState<[Movie]> = .idle
    public private(set) var isLoadingNextPage: Bool = false
    public private(set) var hasReachedEnd: Bool = false

    private let service: any MovieServiceProtocol
    private var currentPage: Int = 0

    public init(service: any MovieServiceProtocol) {
        self.service = service
    }

    public func loadPopular() async {
        state = .loading
        currentPage = 0
        hasReachedEnd = false
        do {
            let page = try await service.popular(page: 1)
            state = .loaded(page.results)
            currentPage = 1
            hasReachedEnd = page.page >= page.totalPages
        } catch let error as MovieServiceError {
            state = .error(error)
        } catch {
            state = .error(.transport(error))
        }
    }

    /// Pull-to-refresh: re-fetches page 1 without hiding currently-loaded data.
    /// State stays `.loaded(currentMovies)` for the duration of the request so
    /// the host List isn't unmounted and the system refresh control completes
    /// naturally. Strict minimum: errors are silently swallowed for now.
    ///
    /// Only valid from `.loaded`. From `.idle` or `.error`, refresh is a no-op
    /// — first load and error retry both belong to `loadPopular()`.
    public func refresh() async {
        guard case .loaded = state else { return }
        currentPage = 0
        hasReachedEnd = false
        if let page = try? await service.popular(page: 1) {
            state = .loaded(page.results)
            currentPage = 1
            hasReachedEnd = page.page >= page.totalPages
        }
    }

    public func loadNextPage() async {
        guard case .loaded(let currentMovies) = state else { return }
        guard !isLoadingNextPage, !hasReachedEnd else { return }

        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        if let nextPage = try? await service.popular(page: currentPage + 1) {
            let existingIDs = Set(currentMovies.map(\.id))
            let fresh = nextPage.results.filter { !existingIDs.contains($0.id) }
            state = .loaded(currentMovies + fresh)
            currentPage += 1
            hasReachedEnd = nextPage.page >= nextPage.totalPages
        }
    }
}
