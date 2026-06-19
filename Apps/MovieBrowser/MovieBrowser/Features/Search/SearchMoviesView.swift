import SwiftUI
import MovieBrowserCore

struct SearchMoviesView: View {
    @State private var viewModel: SearchMoviesViewModel
    private let service: any MovieServiceProtocol

    init(service: any MovieServiceProtocol) {
        self.service = service
        self._viewModel = State(initialValue: SearchMoviesViewModel(service: service))
    }

    var body: some View {
        @Bindable var vm = viewModel
        NavigationStack {
            content
                .searchable(text: $vm.query, prompt: "Search movies")
                .navigationTitle("Search")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView("Search for a movie", systemImage: "magnifyingglass")
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let movies) where movies.isEmpty:
            ContentUnavailableView.search(text: viewModel.query)
        case .loaded(let movies):
            List(movies, id: \.id) { movie in
                NavigationLink {
                    MovieDetailView(service: service, movieID: movie.id)
                } label: {
                    MovieRow(movie: movie)
                }
            }
            .listStyle(.plain)
            .accessibilityIdentifier("searchResultsList")
        case .error(let error):
            ErrorView(error: error) { /* retry by typing */ }
        }
    }
}
