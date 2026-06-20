# Architecture & Project Scope

This repo is an iOS portfolio project: two SwiftUI apps sharing a networking
package, built in strict phase order with TDD. The goal is to showcase modern
Swift, a clean networking abstraction, and Firebase competence behind clean,
recruiter-readable architecture.

## Workspace layout

```
AgenticCodingPortfolio.xcworkspace   # the workspace to open
├── Packages/
│   ├── NetworkKit/                  # transport-only HTTP client (SPM)
│   ├── MovieBrowserCore/            # MovieBrowser models/services/view models (SPM)
│   └── SocialFeedCore/              # SocialFeed domain: models, repo protocols, VMs (SPM, no Firebase)
├── Apps/
│   └── MovieBrowser/                # app target: composition root + SwiftUI views
├── docs/                            # this documentation
└── Archive/                         # the original single-app project, retired
```

Organize by **feature**, not by type. Use `Features/Feed/`, not
`ViewModels/` + `Views/`. **One type per file.**

## Build phases (strict order)

Each phase must be fully complete and green before the next begins.

1. **NetworkKit** — local Swift package. `APIClientProtocol`, a
   `URLSession`-backed `URLSessionAPIClient`, typed `NetworkError`, `Endpoint`,
   `HTTPMethod`. The protocol is transport-only:
   `send(_:) async throws -> (Data, HTTPURLResponse)` — **no decoding**. Decoding
   is a separate concern owned by the service layer (single responsibility).
   _Alamofire is not used anywhere in this project_ — `URLSession` is sufficient
   for both apps (decided 2026-06-17; the original brief's "Alamofire-backed
   client" and "demonstrate interchangeability" requirements were dropped).
2. **MovieBrowser** — TMDB consumer. All calls go through the URLSession-backed
   NetworkKit. Kingfisher for image caching. Paginated popular list, debounced
   search, detail screen.
3. **SocialFeed** _(built; runs live on Firebase)_ — Firebase Auth + Firestore +
   Storage. Email sign-in/sign-up, real-time feed via `AsyncThrowingStream`
   wrapping a Firestore snapshot listener (no Firebase types in view models),
   optimistic likes, compose (text + image upload), and profile. `LinkPreview`
   Open Graph parsing exists in core (UI wiring is a remaining task). Three layers:
   - **`SocialFeedCore`** — pure domain layer: models, repository **protocols**,
     and `@Observable` view models, with **no Firebase import** (the boundary is
     compiler-enforced). All TDD against mocks. See
     [`Packages/SocialFeedCore/README.md`](../Packages/SocialFeedCore/README.md).
   - **`SocialFeedFirebase`** — concrete repositories (Auth, Firestore feed/post/
     profile, Storage) implementing the `SocialFeedCore` protocols against the
     Firebase SDK; `@preconcurrency` import + `nonisolated(unsafe)` for the
     non-Sendable listener handles. The app composes the two; `SocialFeedCore`
     never sees Firebase.
   - **SocialFeed app** — SwiftUI screens (Auth, Feed, Compose, Profile via a
     TabView) + composition root (`RootContainer`). See
     [`Apps/SocialFeed/README.md`](../Apps/SocialFeed/README.md).
   - **Remaining/deferred:** Sign in with Apple (needs an Apple Team),
     `LinkPreviewService` UI + concrete `HTMLLoading`, hermetic UI tests + CI.
   - **Manual prerequisites:** Firebase project, `GoogleService-Info.plist`
     (gitignored), Firestore composite index for the profile query, Storage
     enabled (Blaze plan) for image upload.

## View-model conventions

- View models are **`@MainActor @Observable final class`** types (Observation
  framework, iOS 17+) — **never `ObservableObject`**. `ObservableObject` requires
  Combine, which conflicts with the no-Combine standard. SwiftUI views observe an
  `@Observable` model identically. `PopularMoviesViewModel` is the reference
  implementation. (Locked 2026-06-17.)
- View-model state uses the `LoadState<Value>` enum:
  `.idle / .loading / .loaded(Value) / .error(MovieServiceError)`. There is **no
  `.empty` case** — zero results are `.loaded([])`. See
  [`Packages/MovieBrowserCore/README.md`](../Packages/MovieBrowserCore/README.md)
  for the full legal-transition rules (including why refresh is `.loaded → .loaded`).
- Pagination uses a separate `isLoadingNextPage: Bool`, orthogonal to
  `LoadState`; the state stays `.loaded(T)` while the next page loads.
- View models depend on **protocols** (`any MovieServiceProtocol`), injected via
  `init`. No singletons, no concrete framework imports.
- The composition root wires concrete services; everywhere else depends on
  protocols.

## Locked decisions

- TMDB for MovieBrowser (movies, not recipes). _(2026-06-16)_
- iOS 17 minimum deployment target.
- Restructured into `AgenticCodingPortfolio.xcworkspace`; the original
  `AgenticCodingWithXcode` single app is archived under `Archive/`.
- Bundle ID namespace: **`com.signalzero.portfolio.*`**.
  - SocialFeed: **`com.signalzero.portfolio.socialfeed`** (matches the Firebase
    iOS app / `GoogleService-Info.plist`, project `agentic-coding-ios-swift`).
  - MovieBrowser + NetworkKit currently still use the old `com.ginoalo.portfolio.*`
    IDs (`com.ginoalo.portfolio.moviebrowser`, `com.ginoalo.portfolio.networkkit`)
    — **migration to `com.signalzero.portfolio.*` is pending** (low priority;
    MovieBrowser uses no backend so the rename is cosmetic + a re-sign).
  - The Team is set manually in Signing & Capabilities.
- Sign in with Apple capability is added manually when Phase 3 starts.
- CI: `.github/workflows/ci.yml` runs `swift test` for both packages, then
  builds the MovieBrowser app for the Simulator, on every push/PR to `main`.

## Secrets

TMDB key and `GoogleService-Info.plist` are user-supplied and gitignored —
**never read or commit them**. See [`tmdb-auth.md`](./tmdb-auth.md) for the
injection design.
