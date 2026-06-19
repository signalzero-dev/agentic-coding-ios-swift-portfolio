---
name: add-feature
description: Scaffold a new MovieBrowser screen/feature following this repo's clean-architecture conventions — a TDD-built @Observable view model in MovieBrowserCore plus a SwiftUI view in the app target. Use when adding a new screen, list, or feature to MovieBrowser (or, later, SocialFeed), e.g. "add a favorites screen", "build the genres tab".
---

# Add a feature (this repo)

Features split across two layers: **testable logic** (models, services, view
models) lives in the `MovieBrowserCore` package and is built with TDD; the
**SwiftUI view** lives in the app target and owns the view model. Full rules:
[`docs/architecture.md`](../../../docs/architecture.md) and
[`docs/engineering-standards.md`](../../../docs/engineering-standards.md).

## Steps

1. **Model the data (if new).** Add `Decodable & Sendable` models in
   `Packages/MovieBrowserCore/Sources/MovieBrowserCore/`. TMDB JSON decodes with
   `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase`. TDD the decoding.

2. **Extend the service behind a protocol.** Add the method to
   `MovieServiceProtocol` and implement it in `MovieService`, mapping HTTP/transport/
   decoding failures to typed `MovieServiceError`. Keep `MovieService` auth-agnostic
   — it only uses the injected `APIClientProtocol`. TDD with `MockAPIClient` /
   `URLProtocolStub`; never hit the real network.

3. **Build the view model with TDD.** Use the
   [`tdd-cycle`](../tdd-cycle/SKILL.md) skill. The VM is a
   `@MainActor @Observable final class` that:
   - holds state as `LoadState<Value>` (no `.empty`; zero results are
     `.loaded([])`; obey the legal transitions in
     [`Packages/MovieBrowserCore/README.md`](../../../Packages/MovieBrowserCore/README.md));
   - takes `any MovieServiceProtocol` (and other deps, e.g. `any Clock<Duration>`)
     via `init` — **no singletons, no inline `Service()`**;
   - uses structured concurrency for async work; for typed-input debouncing reuse
     the cancel-and-replace `Task` pattern in
     [`docs/search-debounce.md`](../../../docs/search-debounce.md).
   `PopularMoviesViewModel` is the reference implementation.

4. **Add the SwiftUI view** under
   `Apps/MovieBrowser/MovieBrowser/Features/<FeatureName>/` (by feature, one type
   per file). The owning screen holds the VM with
   `@State private var viewModel = …`; child views needing two-way bindings take
   `@Bindable var viewModel: …`. **Never** `@StateObject` / `@ObservedObject` /
   `ObservableObject`. Render each `LoadState` case (loading / loaded / error via
   the shared `ErrorView`); empty-state UI is the view's responsibility. Use
   Kingfisher for remote images.

5. **Wire at the composition root only.** If the feature needs a new concrete
   dependency, construct it in `RootContainer` / `MovieBrowserApp.swift` and inject
   it down. Secrets follow [`docs/tmdb-auth.md`](../../../docs/tmdb-auth.md) — never
   hardcoded.

6. **Run the suite green** (`swift test --package-path Packages/MovieBrowserCore`)
   and build the app for an iOS 17 Simulator.

## Checklist

- [ ] New logic is in `MovieBrowserCore`, not the app target
- [ ] Tests written first, red before green, Swift Testing
- [ ] VM is `@Observable`, protocol-injected, no force-unwraps, typed errors
- [ ] View uses `@State`/`@Bindable`; concrete wiring only at the composition root
- [ ] No Combine, no CocoaPods, organized by feature
