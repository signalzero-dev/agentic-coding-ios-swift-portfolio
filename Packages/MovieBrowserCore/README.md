# MovieBrowserCore

Models, services, and view models for the MovieBrowser app. Depends on `NetworkKit`.

## Architecture

- **Models** (`Movie`, `MoviePage`) — `Decodable & Sendable`. JSON decoded with `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase` to map TMDB's snake-case keys.
- **Service layer** (`MovieServiceProtocol`, `MovieService`, `MovieServiceError`) — wraps `NetworkKit.APIClientProtocol`. Maps HTTP status codes and transport / decoding failures into typed `MovieServiceError`.
- **View models** — `@MainActor @Observable final class` types (Observation framework, iOS 17+; **not** `ObservableObject`) holding a `LoadState`. They take `any MovieServiceProtocol` via init (DI; no singletons; no concrete framework imports).

The package is auth-agnostic: callers (the app's composition root) construct a pre-authenticated `URLSessionAPIClient` and inject it into `MovieService`. The TMDB token never enters this package.

## LoadState

`LoadState<Value: Sendable>` is the canonical view-model state for asynchronous data loads.

```swift
public enum LoadState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case error(MovieServiceError)
}
```

### Zero-results rule

There is **no `.empty` case**. A successful fetch that returns zero items is `.loaded([])`. Empty-state UI is the view's responsibility — it has the context (search query, filter, page) needed to render a meaningful empty message.

### Legal transitions

```
.idle     → .loading
.loading  → .loaded(T) | .error(E)
.loaded   → .loaded(T')     (in-place refresh — data never disappears)
.error    → .loading        (retry from error)
```

**Forbidden**: `.idle → .loaded` (must pass through `.loading`); `.loaded → .loading` (would unmount the host view and break pull-to-refresh — use in-place refresh instead); `.loaded → .error` directly (use the `.loaded → .loaded(T')` refresh path; failed refresh keeps stale data); `.error → .loaded` directly (must go through `.loading`).

**Why `.loaded → .loaded(T')` for refresh:** Pull-to-refresh in SwiftUI attaches the gesture to the `List` (or whatever view renders the `.loaded` case). Transitioning to `.loading` mid-pull would unmount that List, force-cancel the gesture, and produce the UIKit warning *"Attempting to change the refresh control while it is not idle."* Keep the data visible; let the system refresh control own its own spinner. View models expose this via a separate `refresh()` method, distinct from first-load (`loadPopular()` / `load()`).

**`refresh()` is `.loaded`-only:** It guards `guard case .loaded = state else { return }`. From `.idle` or `.error`, it's a no-op. First load lives in `loadPopular()` (which goes through `.loading`), error retry also calls `loadPopular()`. This keeps the forbidden `.idle → .loaded` and `.error → .loaded` transitions unreachable via the public API.

### Pagination

Pagination uses a separate `isLoadingNextPage: Bool` on the view model, orthogonal to `LoadState`. The state stays `.loaded(T)` while a next page is fetched in the background.
