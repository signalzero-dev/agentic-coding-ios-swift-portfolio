import Foundation
import Observation

@MainActor
@Observable
public final class MovieDetailViewModel {
    public private(set) var state: LoadState<MovieDetails> = .idle

    private let service: any MovieServiceProtocol
    private let movieID: Int

    public init(service: any MovieServiceProtocol, movieID: Int) {
        self.service = service
        self.movieID = movieID
    }

    public func load() async {
        state = .loading
        do {
            let details = try await service.details(id: movieID)
            state = .loaded(details)
        } catch let error as MovieServiceError {
            state = .error(error)
        } catch {
            state = .error(.transport(error))
        }
    }
}
