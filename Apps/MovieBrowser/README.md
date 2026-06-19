# MovieBrowser

iOS 17 SwiftUI app browsing TMDB (popular list, search, movie detail).

## Architecture

- **App target** (`Apps/MovieBrowser/MovieBrowser/`) — composition root + SwiftUI views only.
- **MovieBrowserCore** (`Packages/MovieBrowserCore/`) — models, `MovieService`, view models. All testable logic.
- **NetworkKit** (`Packages/NetworkKit/`) — generic URLSession-backed `APIClientProtocol`. Transitive via Core.

**Composition root** lives in `MovieBrowserApp.swift` + `Composition/`:
- `RootContainer.makeProduction()` reads the TMDB token (via `Secrets`), constructs `URLSessionAPIClient(baseURL: "https://api.themoviedb.org/3", defaultHeaders: ["Authorization": "Bearer \(token)"])`, wraps it in `MovieService`, and exposes it as `any MovieServiceProtocol` to the view layer.
- The token never appears in source. It enters via `Secrets.xcconfig` → `Info.plist` substitution → `Bundle.main` lookup.

**View ownership**: view models are `@MainActor @Observable`. Views own them via `@State` and pass bindings down via `@Bindable`. No `ObservableObject` / `@StateObject` / `@ObservedObject` anywhere — the Observation framework only.

## Running locally

1. **Get a TMDB v4 Read Access Token** at https://www.themoviedb.org/settings/api (v4 auth section).
2. **Create your local secrets file**:
   ```
   cp Apps/MovieBrowser/Config/Secrets.xcconfig.template \
      Apps/MovieBrowser/Config/Secrets.xcconfig
   ```
   Paste your token into `Secrets.xcconfig`. Do not commit it.
3. **Open the workspace**: `AgenticCodingPortfolio.xcworkspace`.
4. **Verify these target-level settings** (one-time Xcode wiring; see "First-time Xcode setup" below if not yet done):
   - Package dependencies include `MovieBrowserCore` (local) and `Kingfisher` (remote).
   - Build Settings → Configurations point at `Secrets.xcconfig`.
   - Info has key `TMDB_BEARER_TOKEN` with value `$(TMDB_BEARER_TOKEN)`.
5. Select the **MovieBrowser** scheme + an iOS 17 Simulator. **Cmd+R**.

## First-time Xcode setup (one-time)

These steps wire the target to the package + Kingfisher + the xcconfig. They can't be done via plain source edits.

### 1. Add Swift Package dependencies
File → Add Package Dependencies… and add:
- **Local**: choose "Add Local…" → select `Packages/MovieBrowserCore`. Add product **MovieBrowserCore** to the MovieBrowser app target.
- **Remote**: `https://github.com/onevcat/Kingfisher` — pin to **Exact 8.0.0** or **Up to Next Major from 8.0.0**. Add product **Kingfisher** to the MovieBrowser app target.

### 2. Set the Configuration File
Project navigator → MovieBrowser project → **Info** tab → "Configurations" section. For both Debug and Release of the MovieBrowser **target**, set the file to `Apps/MovieBrowser/Config/Secrets.xcconfig`.

### 3. Add the Info.plist key for the token
Target → **Info** tab → "Custom iOS Target Properties" → add row:
- **Key**: `TMDB_BEARER_TOKEN`
- **Type**: `String`
- **Value**: `$(TMDB_BEARER_TOKEN)`

Xcode substitutes from the xcconfig at build time; `Secrets.swift` reads from `Bundle.main.object(forInfoDictionaryKey:)` at runtime.

### 4. Share the `MovieBrowser` scheme (needed for CI)
By default the scheme lives in `xcuserdata` (gitignored), so it doesn't exist on
a fresh CI checkout. Product → Scheme → **Manage Schemes…** → tick **Shared** for
`MovieBrowser`, then commit the file Xcode writes to
`…/MovieBrowser.xcodeproj/xcshareddata/xcschemes/MovieBrowser.xcscheme`. This makes
`xcodebuild -scheme MovieBrowser` deterministic instead of relying on auto-creation.

### 5. (Deferred) Signing
Team is intentionally unset — the app builds for Simulator without signing. Set Team in Signing & Capabilities when you want to install on a device.

## Tests

- **Package tests** (the bulk of the logic) run via `swift test --package-path Packages/NetworkKit` and `swift test --package-path Packages/MovieBrowserCore`.
- **App-target tests** run through Xcode / `xcodebuild` against a Simulator:
  ```
  # Boot the Simulator first (warm sim avoids a flaky XCUITest runner-init timeout),
  # then run serially (parallel cloned sims can crash the runner under load):
  xcrun simctl boot 'iPhone 17' || true
  xcodebuild test \
    -workspace AgenticCodingPortfolio.xcworkspace \
    -scheme MovieBrowser \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -parallel-testing-enabled NO
  ```
  - `MovieBrowserUITests` drives the three core journeys (popular list loads, tap → detail, debounced search) end-to-end.
  - `MovieBrowserTests` covers the UI-test harness (`StubMovieService`). Composition wiring itself is not unit-tested — that's verified by the build.
  - **Reliability note:** XCUITest can fail with *"the test runner failed to initialize for UI testing — Timed out waiting for AX loaded notification"* on a cold or parallel-cloned Simulator. That's an infrastructure flake, not a test failure — pre-boot the Simulator and pass `-parallel-testing-enabled NO`.
- **Hermetic UI tests:** the UI tests launch the app with the `-uiTestStub` argument, which makes the composition root use `StubMovieService` (in-memory JSON fixtures) instead of the live TMDB client. So they need **no token and no network** and stay deterministic. See `MovieBrowser/Composition/RootContainer.swift`.
- CI (`.github/workflows/ci.yml`) runs both package test suites + builds the app for Simulator on every push/PR to `main`. (The UI tests can be added to CI by switching the build-app job to `xcodebuild test`.)
