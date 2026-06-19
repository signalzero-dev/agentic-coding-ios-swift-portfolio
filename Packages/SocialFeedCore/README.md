# SocialFeedCore

Pure domain layer for the SocialFeed app — models, repository **protocols**, and
`@Observable` view models. **No Firebase dependency**: the concrete Firebase
implementations live in a separate `SocialFeedFirebase` package (later increment),
so the compiler enforces that view models never import a vendor SDK.

## Architecture

- **Models** (`User`, `Post`) — pure `Sendable` value types. No Firebase, no
  `Decodable` (Firestore ↔ domain mapping happens in `SocialFeedFirebase`).
- **Repository protocols** (`AuthRepository`, `FeedRepository`) — `Sendable`
  abstractions the app composes against. Real-time flow is exposed as
  `AsyncStream` / `AsyncThrowingStream` (Combine-free):
  - `AuthRepository.authStateStream() -> AsyncStream<User?>` — emits on every
    sign-in / sign-out / token refresh; drives the session.
  - `FeedRepository.feedStream() -> AsyncThrowingStream<[Post], Error>` — live feed;
    throws to terminate on listener failure (permission denied, network).
- **View models** (`@MainActor @Observable final class`) — hold a
  [`LoadState`](Sources/SocialFeedCore/LoadState.swift) and take repositories via
  `init` (DI; no singletons; no concrete framework imports):
  - `AuthViewModel` — `session: User?` driven by `authStateStream`; `signInState`
    tracks the in-flight sign-in.
  - `FeedViewModel` — consumes `feedStream()` in a cancellable `Task`; real-time
    updates stay in-place (`.loaded → .loaded`). `toggleLike(_:)` updates the local
    list **optimistically**, persists via `LikeRepository`, and rolls back on failure.
- **`LinkPreviewService`** — builds a `LinkPreview` by loading a page's HTML
  (injected `HTMLLoading`) and parsing its Open Graph (`og:*`) meta tags. The
  parser is the tested core; the concrete URLSession/NetworkKit loader is an
  app-layer detail (deferred).

## LoadState

`LoadState<Value: Sendable, Failure: Error & Sendable>` is the canonical async
view-model state — like MovieBrowserCore's, but **generic over the error type** so
each view model pairs it with its own typed error (`AuthError`, `FeedError`).
Same discipline: no `.empty` case (zero results are `.loaded([])`); real-time
refreshes are in-place `.loaded → .loaded` so data never disappears mid-update.

## Status

Built test-first against mock repositories (no backend required). Done so far:
**Auth**, **read-only real-time feed**, **optimistic likes**, and
**LinkPreviewService** (Open Graph parsing). Deferred to later increments:
`SocialFeedFirebase` (concrete repos), the SwiftUI app target + Sign in with Apple,
the concrete URLSession/NetworkKit `HTMLLoading`, and the remaining features
(image-upload compose, profile).

## Tests

```
swift test --package-path Packages/SocialFeedCore
```

Swift Testing throughout; repositories are mocked (`TestSupport/`). A bounded
`waitFor` helper lets a test await a view model's stream-consuming `Task` without
hand-rolling fragile sleeps.
