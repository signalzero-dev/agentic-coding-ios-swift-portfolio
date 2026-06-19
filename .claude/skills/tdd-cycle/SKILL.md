---
name: tdd-cycle
description: Run the strict red-green-refactor TDD loop for this repo's Swift packages (NetworkKit, MovieBrowserCore). Use whenever adding or changing behavior in package code — writing a failing Swift Testing test first, confirming it fails for the right reason, then making it pass. Invoke for "add a test", "TDD this", "implement X with tests", or any new package behavior.
---

# TDD cycle (this repo)

This repo mandates strict TDD for **every** unit of behavior. Logic lives in the
SPM packages (`Packages/NetworkKit`, `Packages/MovieBrowserCore`) and is tested
with **Swift Testing** (`import Testing`, `@Test`, `#expect`/`#require`), never
XCTest. Background: [`docs/engineering-standards.md`](../../../docs/engineering-standards.md).

## The loop — repeat per unit of behavior

1. **RED — write one failing test first.**
   - Put it in the matching `Tests/<Package>Tests/` target. Mirror existing
     files (e.g. `PopularMoviesViewModelTests.swift`).
   - Use protocol mocks/stubs from `TestSupport/` (`MockMovieService`,
     `MockAPIClient`, `URLProtocolStub`). **No real network** — stub `URLSession`
     via `URLProtocol`. **No live services.**
   - For time-dependent behavior, inject a `Clock` and use `swift-clocks`
     `TestClock` (test-target-only dep). See
     [`docs/search-debounce.md`](../../../docs/search-debounce.md).
2. **Confirm it fails for the right reason.** Run the suite and read the failure
   — it must fail on the new assertion, not a compile error in unrelated code or
   a typo. If a freshly written test passes immediately, the cycle isn't real:
   either the behavior isn't new (move on) or the test isn't sharp enough
   (sharpen it until it fails first). **Never** skip a test claiming "it would
   already pass."
3. **GREEN — write the minimum code to pass.** Honor the standards: Swift 6
   strict concurrency, `async`/`await`, no Combine, protocol-injected
   dependencies, no force-unwraps, typed errors.
4. **Run the suite green.**
5. **REFACTOR — clean up with the suite green**, then run green again.
6. **Summarize** what changed and what's next, then start the next cycle.

## Running tests

```bash
swift test --package-path Packages/NetworkKit
swift test --package-path Packages/MovieBrowserCore
# focus one suite/test:
swift test --package-path Packages/MovieBrowserCore --filter SearchMoviesViewModelTests
```

## Conventions to keep

- View models under test are `@MainActor @Observable final class` holding a
  `LoadState<Value>`; assert on `state` transitions. Remember there is **no
  `.empty`** — zero results are `.loaded([])`. Legal transitions:
  [`Packages/MovieBrowserCore/README.md`](../../../Packages/MovieBrowserCore/README.md).
- One type per file; organize by feature.
- "Generic" means type-parameterized — don't call a sample/stub type "generic".
