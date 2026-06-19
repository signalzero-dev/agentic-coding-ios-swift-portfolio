# Engineering Standards

Non-negotiable rules for this repo. Apply to **every** code change. The rationale
throughout is SOLID + testability + recruiter-readable portfolio code.

Before writing implementation code, ask: _Is there a failing test? Is this view
model importing a concrete framework? Is this service being newed up inline?_ If
any answer is wrong, fix the design first.

## Concurrency

- **Swift 6, strict concurrency.** `async`/`await` everywhere. No completion
  handlers.
- **No Combine.** Use `AsyncStream` / `AsyncSequence` where reactive flow is
  needed. (This is why view models are `@Observable`, not `ObservableObject` —
  see [architecture.md](./architecture.md).)

## Test-driven development

- **TDD for every unit of behavior. Strict red → green → refactor, always.**
  Write a failing test first → confirm it fails for the right reason → write the
  minimum code to pass → run the suite green → refactor → green. After each green
  cycle, summarize what changed and what's next.
- **Do not skip a test on the grounds that "it would already pass."** If a
  proposed test passes immediately, either (a) the behavior isn't genuinely new
  and the cycle isn't real — move to actually-new behavior, or (b) the test isn't
  sharp enough — sharpen it until it fails first.
- **Swift Testing** framework (`import Testing`, `@Test`, `#expect`), not XCTest,
  unless a tool forces otherwise — flag it if so.
- **Tests use protocol mocks/stubs.** No real network in tests — use a
  `URLProtocol` stub for `URLSession`. No live Firebase in tests.
- **Verified-correct beats hand-rolled** when choosing test infrastructure
  (clocks, mocks, schedulers, harnesses). A trusted third-party _test-only_
  dependency is preferable to hand-rolling concurrency primitives we might get
  subtly wrong (false greens). The criterion is correctness, not "Apple-vendor."
  Example: `SearchMoviesViewModel` injects a `Clock`, and tests use Point-Free's
  `swift-clocks` `TestClock` (a test-target-only dependency). See
  [search-debounce.md](./search-debounce.md).

The full TDD loop is also available as the **`tdd-cycle`** skill.

## Dependency injection & architecture

- **View models depend on protocols, never concrete types.** No view model
  imports Firebase or Alamofire directly. Those live behind protocol-abstracted
  repositories/services.
- **Dependency injection at a composition root.** No singletons. No inline
  `Service()` constructed inside a view model.
- **SwiftUI view-model ownership: `@State` + `@Bindable`, NOT `@StateObject` /
  `@ObservedObject`.** View models are `@MainActor @Observable` classes. The
  screen that owns a VM holds it with `@State private var viewModel = …`; child
  views that need two-way bindings take `@Bindable var viewModel: …` (e.g.
  `TextField(text: $viewModel.query)`). Pass the VM down via `init` or
  `.environment(_:)`. `@StateObject` / `@ObservedObject` belong to Combine's
  `ObservableObject` world, which we explicitly removed.

## Packaging & safety

- **SPM only.** Never CocoaPods, never a Podfile.
- **No force-unwraps in production paths.** Exhaustive error handling with typed
  errors (e.g. `MovieServiceError`, `NetworkError`, `StartupError`).

## Vocabulary precision — "generic"

In Swift code, comments, and discussion, **generic** means _type-parameterized_
(`func send<T: Decodable>`, `Array<Element>`, `Box<T>`). Do **not** use it as a
synonym for "sample," "example," "placeholder," or "ordinary." A type like
`struct SampleDTO { let id: Int; let title: String }` is **concrete**, not
generic. Call a throwaway type "a concrete sample type" / "an inline placeholder
DTO" / "a stand-in for the real model." Audit comments and PR descriptions for
the same slip.
