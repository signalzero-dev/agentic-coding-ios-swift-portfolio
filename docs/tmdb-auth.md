# TMDB Auth — Token Injection

How the TMDB v4 Read Access Token reaches the running MovieBrowser app **without
ever appearing in source or any committed file**. (Locked 2026-06-17.)

Authentication uses the TMDB **v4 Read Access Token** as an
`Authorization: Bearer <token>` header.

## Layering rule — the token never crosses package boundaries

- **`NetworkKit`** knows nothing about TMDB or any token.
- **`MovieBrowserCore`** knows nothing about the token. `MovieService` accepts an
  `APIClientProtocol` whose auth header is already pre-set; the service treats
  auth as opaque.
- Only the **MovieBrowser app target's composition root**
  (`RootContainer.makeProduction()`) constructs the authenticated client:
  ```swift
  URLSessionAPIClient(
      baseURL: URL(string: "https://api.themoviedb.org/3")!,   // illustrative
      defaultHeaders: ["Authorization": "Bearer \(token)"]
  )
  ```
  and injects it into `MovieService`. The base URL also originates here, never
  hardcoded inside the package.

## Token storage (app target only)

| File | Committed? | Contents |
| --- | --- | --- |
| `Apps/MovieBrowser/Config/Secrets.xcconfig` | **No** (gitignored) | the literal token, pasted locally |
| `Apps/MovieBrowser/Config/Secrets.xcconfig.template` | **Yes** | documents the required key `TMDB_BEARER_TOKEN`, no real value |

Flow at build/run time:

```
Secrets.xcconfig  ──(Xcode build-time substitution)──▶  Info.plist key
   TMDB_BEARER_TOKEN = …              TMDB_BEARER_TOKEN = $(TMDB_BEARER_TOKEN)
                                                  │
                                                  ▼
   Secrets.tmdbBearerToken()  ◀──  Bundle.main.object(forInfoDictionaryKey:)
                                                  │
                                                  ▼
            RootContainer  ──(throws StartupError if missing)──▶  injected client
```

`Secrets.swift` reads `Bundle.main.object(forInfoDictionaryKey: "TMDB_BEARER_TOKEN")`
and rejects empty / unsubstituted values; the composition root throws a typed
`StartupError` (rendered by `StartupErrorView`) if the token is missing — **no
force-unwrap**.

## Rules

- **Never** write the TMDB token into any source file, fixture, doc, or commit.
- When wiring the app, follow the xcconfig → Info.plist → Bundle accessor →
  composition-root flow above. (See "First-time Xcode setup" in the
  [app README](../Apps/MovieBrowser/README.md) for the one-time target wiring.)
- Tests never need the token — they inject mocked `APIClientProtocol` /
  `MovieServiceProtocol` instances.
- If a future CI job runs the app **build** (not just tests), inject
  `TMDB_BEARER_TOKEN` via an environment variable consumed by the xcconfig at
  build time. CI currently writes a placeholder `Secrets.xcconfig` for the build
  step (see `.github/workflows/ci.yml`).

This same pattern generalizes to any future injected secret (e.g.
`GoogleService-Info.plist` for SocialFeed): keep it gitignored, inject it at the
composition root, and keep packages secret-agnostic.
