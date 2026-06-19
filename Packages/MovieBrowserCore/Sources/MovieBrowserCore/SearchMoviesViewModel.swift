import Foundation
import Observation

@MainActor
@Observable
public final class SearchMoviesViewModel {
    public private(set) var state: LoadState<[Movie]> = .idle
    public var query: String = "" {
        didSet { onQueryChanged() }
    }

    private let service: any MovieServiceProtocol
    private let clock: any Clock<Duration>
    private var searchTask: Task<Void, Never>?

    public init(
        service: any MovieServiceProtocol,
        clock: any Clock<Duration> = ContinuousClock()
    ) {
        self.service = service
        self.clock = clock
    }

    private func onQueryChanged() {
        searchTask?.cancel()
        let currentQuery = query
        guard !currentQuery.isEmpty else { return }
        searchTask = Task {
            do {
                try await self.clock.sleep(for: .milliseconds(300))
            } catch {
                return
            }
            self.state = .loading
            do {
                let page = try await self.service.search(query: currentQuery, page: 1)
                self.state = .loaded(page.results)
            } catch let error as MovieServiceError {
                self.state = .error(error)
            } catch {
                self.state = .error(.transport(error))
            }
        }
    }
}
