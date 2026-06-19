import SwiftUI
import MovieBrowserCore

struct MainTabView: View {
    let service: any MovieServiceProtocol

    var body: some View {
        TabView {
            PopularMoviesView(service: service)
                .tabItem { Label("Popular", systemImage: "film") }
            SearchMoviesView(service: service)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
        }
    }
}
