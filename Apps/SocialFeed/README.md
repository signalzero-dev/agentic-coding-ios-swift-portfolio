# SocialFeed

iOS 17 SwiftUI app: a Firebase-backed social feed (email auth, real-time posts,
optimistic likes, compose with image upload, profile).

## Architecture

Three layers, with Firebase kept entirely out of the view layer:

- **App target** (`Apps/SocialFeed/SocialFeed/`) — composition root + SwiftUI
  views only. Imports `SocialFeedCore` + `SocialFeedFirebase`; **never** imports
  Firebase directly.
- **`SocialFeedCore`** (`Packages/SocialFeedCore/`) — pure domain layer: models,
  repository **protocols**, `@Observable` view models, generic `LoadState`. No
  Firebase. Fully unit-tested (TDD against mocks).
- **`SocialFeedFirebase`** (`Packages/SocialFeedFirebase/`) — concrete Firebase
  implementations of the `SocialFeedCore` protocols (Auth, Firestore feed/post/
  profile, Storage). The only module that imports Firebase.

**Composition root** is `RootContainer` (+ `SocialFeedApp`): it calls
`SocialFeedFirebaseApp.configure()` at launch, constructs the concrete
repositories, and builds the view models. The view layer depends only on
`SocialFeedCore` protocols — so it's the same dependency-inversion pattern as
MovieBrowser, with Firebase swapped in behind protocols instead of `URLSession`.

**View ownership**: view models are `@MainActor @Observable`; views own them via
`@State` and bind with `@Bindable`. No `ObservableObject` / Combine.

## Features

- **Auth** — email/password **sign-in and sign-up** (auto-signs-in). Session is
  driven by Firebase's auth-state listener wrapped in an `AsyncStream`.
- **Feed** — real-time `posts` via a Firestore snapshot listener wrapped in an
  `AsyncThrowingStream`; in-place updates so the list never unmounts.
- **Likes** — optimistic local update → `arrayUnion`/`increment` in Firestore →
  the listener echoes the authoritative state.
- **Compose** — text + optional photo (PhotosPicker → jpeg-compressed → Storage).
- **Profile** — the signed-in user's posts (filtered Firestore stream).

Sign in with Apple is deferred until an Apple Developer Team is configured.

## Running locally

1. Open `AgenticCodingPortfolio.xcworkspace`, select the **SocialFeed** scheme.
2. **Firebase prerequisites** (one-time, in the Firebase console for your project):
   - Add an iOS app with bundle ID **`com.signalzero.portfolio.socialfeed`** and
     drop its `GoogleService-Info.plist` into `Apps/SocialFeed/SocialFeed/`
     (gitignored — never commit it).
   - **Authentication** → enable **Email/Password**.
   - **Firestore** → create the database; rules allowing authed read/create/update
     on `posts`; create the composite index it prompts for (the profile query
     needs `authorID` + `createdAt`).
   - **Storage** (optional, for image posts; requires the Blaze plan) → enable +
     authed read/write rules.
3. Build & run. Sign up or sign in, and the feed loads in real time.

### `posts/{id}` document schema
`authorID: String`, `authorName: String`, `text: String`, `createdAt: Timestamp`,
`imageURL: String?`, `likeCount: Int`, `likedBy: [String]`.

## Tests

- **Core logic**: `swift test --package-path Packages/SocialFeedCore` (Swift
  Testing; all view models + `LoadState` covered, no backend needed).
- The app target's UI/integration tests are a remaining task (a `-uiTestStub`
  hermetic mode mirroring MovieBrowser would make them backend-free).
- CI runs the package suites; the SocialFeed app build is verified locally (a
  per-push Firebase compile is intentionally kept out of CI).
