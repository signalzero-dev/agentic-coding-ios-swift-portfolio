# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

An iOS portfolio project: two SwiftUI apps sharing a networking package, built in
strict phase order with TDD. Phase 1 (**NetworkKit**) and Phase 2
(**MovieBrowser**) exist; Phase 3 (**SocialFeed**) is not yet built. Full scope,
workspace layout, and locked decisions are in
[`docs/architecture.md`](docs/architecture.md).

Open `AgenticCodingPortfolio.xcworkspace`. The retired original single app lives
under `Archive/` — don't edit it.

## Keep docs in sync with the code

The `/docs` files, the package READMEs, and this file are the source of truth and
must always reflect the codebase. When a change makes any of them stale, update
the relevant doc **in the same change** — don't leave docs describing how things
used to work. Concretely: if you alter a convention, an architecture decision, a
public API, the `LoadState` rules, the secret-injection flow, the build/test
commands, or anything else a doc describes, edit that doc (and add a new one if a
new area warrants it). A change that contradicts the docs isn't done until the
docs match.

## Non-negotiable standards

Read [`docs/engineering-standards.md`](docs/engineering-standards.md) before
writing code. The essentials:

- **Swift 6, strict concurrency. `async`/`await` only. No Combine** — use
  `AsyncStream` / `AsyncSequence` for reactive flow.
- **TDD, strict red → green → refactor, for every unit of behavior.** Never skip
  a test because "it would already pass." Use **Swift Testing**, not XCTest. The
  full loop is the [`tdd-cycle`](.claude/skills/tdd-cycle/SKILL.md) skill.
- **View models are `@MainActor @Observable final class`** — never
  `ObservableObject`. SwiftUI ownership is `@State` + `@Bindable`, never
  `@StateObject` / `@ObservedObject`.
- **View models depend on protocols injected via `init`.** No singletons, no
  inline `Service()`. Concrete wiring happens only at the composition root.
- **SPM only** (never CocoaPods). **No force-unwraps** in production paths — use
  typed errors.
- Organize **by feature**, one type per file.
- "Generic" means _type-parameterized_ — never use it for "sample/example."

## Key conventions

- **`LoadState<Value>`** (`.idle / .loading / .loaded / .error`) is the canonical
  view-model state. No `.empty` case — zero results are `.loaded([])`. Legal
  transitions (and why refresh is `.loaded → .loaded`) are documented in
  [`Packages/MovieBrowserCore/README.md`](Packages/MovieBrowserCore/README.md).
- **NetworkKit is transport-only**: `APIClientProtocol.send(_:)` returns
  `(Data, HTTPURLResponse)` — decoding belongs to the service layer.
- **Secrets are never committed or read into source.** TMDB token injection is
  documented in [`docs/tmdb-auth.md`](docs/tmdb-auth.md). Search debouncing uses
  structured-concurrency cancellation — see
  [`docs/search-debounce.md`](docs/search-debounce.md).

## Adding a feature

Use the [`add-feature`](.claude/skills/add-feature/SKILL.md) skill, or follow the
pattern: TDD the view model + service logic in `MovieBrowserCore` (Swift
Testing), then add the SwiftUI view under `Apps/MovieBrowser/.../Features/<Name>/`
owning the VM with `@State`.

## Build & test

```bash
# Package logic (the bulk of the tests) — fast, no Simulator
swift test --package-path Packages/NetworkKit
swift test --package-path Packages/MovieBrowserCore

# App-target unit + UI tests — needs a Simulator.
# Boot it first (warm) and run serially, or XCUITest may hit a flaky
# "test runner failed to initialize — Timed out waiting for AX loaded notification".
xcrun simctl boot 'iPhone 17' || true
xcodebuild test -workspace AgenticCodingPortfolio.xcworkspace \
  -scheme MovieBrowser -destination 'platform=iOS Simulator,name=iPhone 17' \
  -parallel-testing-enabled NO
```

Tests are the source of truth — keep them green. Most logic is tested in the
packages. The app target adds `MovieBrowserUITests` (core journeys, end-to-end)
and `MovieBrowserTests` (guards the `StubMovieService` UI-test harness).
**UI tests are hermetic:** launching with `-uiTestStub` makes the composition
root use `StubMovieService` (in-memory fixtures) — no token, no network. See
`Apps/MovieBrowser/MovieBrowser/Composition/RootContainer.swift`. CI
(`.github/workflows/ci.yml`) runs both package suites and builds the app for the
Simulator on every push/PR to `main`.

To run the app, copy `Apps/MovieBrowser/Config/Secrets.xcconfig.template` to
`Secrets.xcconfig`, paste a TMDB v4 token, then build the **MovieBrowser** scheme
for an iOS 17 Simulator. See [`Apps/MovieBrowser/README.md`](Apps/MovieBrowser/README.md).

## Further docs

- [`docs/architecture.md`](docs/architecture.md) — scope, phases, layout, locked decisions
- [`docs/engineering-standards.md`](docs/engineering-standards.md) — the full standards
- [`docs/tmdb-auth.md`](docs/tmdb-auth.md) — secret injection design
- [`docs/search-debounce.md`](docs/search-debounce.md) — debounce + clock injection
- [`Packages/MovieBrowserCore/README.md`](Packages/MovieBrowserCore/README.md) — `LoadState` rules
- [`Apps/MovieBrowser/README.md`](Apps/MovieBrowser/README.md) — running the app, Xcode wiring
