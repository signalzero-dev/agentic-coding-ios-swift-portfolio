import SwiftUI

@main
struct MovieBrowserApp: App {
    private let setupResult: Result<RootContainer, StartupError>

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiTestStub") {
            setupResult = .success(.makeUITestStub())
            return
        }
        #endif
        do {
            setupResult = .success(try RootContainer.makeProduction())
        } catch let error as StartupError {
            setupResult = .failure(error)
        } catch {
            setupResult = .failure(.unknown(error.localizedDescription))
        }
    }

    var body: some Scene {
        WindowGroup {
            switch setupResult {
            case .success(let container):
                MainTabView(service: container.movieService)
            case .failure(let error):
                StartupErrorView(error: error)
            }
        }
    }
}
