# Search Debounce Strategy

`SearchMoviesViewModel` debounces search-as-you-type using Swift structured
concurrency cancellation — **not** Combine's `.debounce(for:)`. (Locked
2026-06-17; clock injection added 2026-06-18.)

## Pattern

- The view model holds `private var searchTask: Task<Void, Never>?`.
- Each `query` change (via `didSet`) cancels `searchTask` and replaces it with a
  new `Task` that:
  1. `try await clock.sleep(for: .milliseconds(300))` — the debounce window.
  2. If still not cancelled, calls `service.search(query:page:)`.
  3. Updates `LoadState` on success / error like the other view models.
- `Clock.sleep(for:)` throws `CancellationError` when its surrounding `Task` is
  cancelled — that is how rapid query changes cleanly abandon prior in-flight
  work without the service ever being hit. An empty query short-circuits (no
  task scheduled).

300 ms is the standard typing-debounce window.

## Clock injection

```swift
public init(
    service: any MovieServiceProtocol,
    clock: any Clock<Duration> = ContinuousClock()
)
```

- Production clock: `ContinuousClock` (stdlib), the default.
- Test clock: Point-Free's **`swift-clocks`** `TestClock` (`import Clocks`), a
  **test-target-only** dependency on `MovieBrowserCoreTests` — not a library dep.
- Clock injection scope is `SearchMoviesViewModel` only — not NetworkKit, not
  `MovieService`, not other view models.

This is a concrete application of the "verified-correct beats hand-rolled"
test-infrastructure principle in [engineering-standards.md](./engineering-standards.md).

## Rules

- **Do not** introduce `Combine.Publishers.Debounce`, `Timer`,
  `DispatchQueue.asyncAfter`, or any external scheduler. Pure structured
  concurrency only.
- When extending to other typed-input flows (e.g. in SocialFeed), reuse the same
  pattern: private `Task?`, cancel + replace, sleep + call.

## How to test it

Issue N rapid `query` changes with no awaits between them (e.g. `"a"`, `"ap"`,
`"app"`, `"appl"`, `"apple"`), then advance the injected `TestClock` past 300 ms.
Assert `mockService.searchCallCount == 1` and the captured query is the final
value (`"apple"`).
