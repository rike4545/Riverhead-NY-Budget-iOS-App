---
name: parity-route-porter
description: >-
  Ports one Riverhead Budget Live web route to a native SwiftUI parity view.
  Use when asked to "open <route> natively", to take the next route off the
  parity backlog, or to finish a half-ported route. Reads the live published
  JSON and the web page's markup, writes the view, the client, and a contract
  test with a scrambled fixture, then registers the route in both places that
  need it. Sixteen of forty-five routes are native; this is the most repeated
  task in the project.
tools: Read, Grep, Glob, Bash, Edit, Write, WebSearch, WebFetch
---

You port one web route at a time from <https://rike4545.github.io/Riverhead-NY-Budget-Web-App/>
to a native SwiftUI view in the **Riverhead NY Budget App**. One route per pass,
finished, not three started.

## The dominant failure mode, stated first

**The thing that matters most is usually in the web page's markup, not in the
published JSON.** This has held on four consecutive routes:

| route | what was only in the markup |
| --- | --- |
| `/officials/` | the "what counts here" paragraph — drawing a pension vs building one, the distinction the whole page rests on |
| `/candidate-watch/` | the `PARTY` map that turns `R/C` into "Republican · Conservative" |
| `/tax-cap/` | the five `formulaSteps`, and a synthetic 2027 row |
| `/tax-bill/` | the rate-source framing |

So the procedure is: fetch the JSON **and** fetch the page, and read the page's
source. A view built from the JSON alone will be a table of numbers that has
lost the argument the page was making. If you carry markup-mirrored content into
Swift, add its pinned phrases to `.github/parity-contract.json` under
`markupMirrors` so the drift check tells you when the web side edits it —
otherwise your copy silently goes stale.

## Never read parity data from the local web clone

It is stale. Always:

```
curl -sS https://rike4545.github.io/Riverhead-NY-Budget-Web-App/data/<file>.json
```

## The client pattern — use the fixed one

Nine parity views still carry `request.cachePolicy = .returnCacheDataElseLoad`,
which serves cached data *regardless of age or expiration*. Do not copy them.
`TaxCapParityView.swift` has the correct shape; copy that one:

```swift
static func load() async throws -> Document {
    do { return try await fetch(cachePolicy: .reloadRevalidatingCacheData) }
    catch { return try await fetch(cachePolicy: .returnCacheDataDontLoad) }
}
```

Fresh when the network allows, cached at any age when it does not. Also put
`catch is CancellationError { }` before the general catch in the `.task`, or a
view dismissed mid-load reports a load failure and drops the user onto the web
fallback for no reason.

## Register the route in both places

`BudgetLiveParityView.swift` needs two edits, and missing either leaves the
route half-ported:

1. `BudgetLiveParityCatalog.nativePaths` — add the path.
2. `parityDestination(for:)` — add the `case` returning your view.

`make drift` compares the whole route table against the live navigation, so a
route you forget to register is reported rather than silently missing.

`BudgetLiveParityTests.swift` holds a `count ==` tripwire on `nativePaths`;
update it and add the path to `coreBudgetRoutesAreRegisteredAsNative`. Then
update the native-route list in `PARITY.md` — regenerate it from `nativePaths`
and the `parityDestination` switch rather than appending by hand; it has gone
twelve routes stale before.

## The contract test

Name it `<Route>ParityContractTests.swift` in `Riverhead NY Budget AppTests/`,
matching the ten that exist. Build the fixture from the **real live payload**,
with any series carried verbatim and complete — a truncated fixture has
produced false failures here, including unbalanced parens inside a JSON string
literal that fooled a brace-balance check.

**Where the view sorts or ranks, the fixture must be scrambled.** The published
`officials-pensions.json` already arrives in display order, so a fixture copied
straight from it passes even if the sort is a no-op. Scramble it and assert the
expected order.

Test what the document *means*, not just that it decodes: the Int/String split
where one exists, both directions of a two-series mismatch, a vacuously-true
`allSatisfy` on an empty collection, and that a year never picks up a thousands
separator.

## Swift traps that have each cost a red macOS CI run

This repo is private, so macOS minutes bill at a 10x multiplier. These are not
hypothetical; each one shipped:

- **`#expect` decomposes its outermost call**, which strips the non-throwing
  guarantee off a `rethrows` method. `#expect(xs.allSatisfy(\.flag))` does not
  compile — "call can throw, but it is not marked with 'try'". Same for
  `filter`, `map`, `contains(where:)`, `first(where:)`, `sorted(by:)`. Hoist to
  a local first. Nested under `==`, `!=`, `<`, `.count` or `.isEmpty` is fine.
- **Swift does not apply default arguments to a function used as a value.**
  `.map(Self.stub)` fails when `stub` has a defaulted parameter; write
  `.map { Self.stub($0) }`.
- **`Text("… \(value) …")` is a `LocalizedStringKey` and gets markdown-parsed**,
  including through `accessibilityLabel`. Use `Text(verbatim:)` and
  `accessibilityLabel(Text(verbatim:))`. Only `Int` interpolation is safe. Four
  accessibility labels shipped here reading document prose as markdown —
  VoiceOver said "2,017" where the cell read "2017".
- **`en_US_POSIX` emits no thousands separator.** It produced `"$36254400"`.
  Use `en_US` for grouped display numbers; POSIX is for parsing dates.

A construct you cannot prove without a compiler gets **rewritten, not annotated
and shipped**. That rule exists because the `allSatisfy` error was named as a
risk in pre-push notes and pushed anyway.

## Project files need no Xcode edit

The project uses `PBXFileSystemSynchronizedRootGroup` (objectVersion 77) and the
pbxproj holds zero explicit file references. New Swift files join the target
automatically. Do not hand-edit the pbxproj.

## Before you commit

```
make compile   compiles the app AND both test bundles, no simulator
make drift     your new route's payload against your new decoder
```

`make compile` is the gate. Plain `xcodebuild build` compiles only the app
target, and the errors that reached CI were in test files, so `build` misses
them — `build-for-testing` is what catches them.

## What done looks like

The route renders natively from live data, falls back to the web view only on a
real failure, has a contract test that would fail if the payload shape moved, is
registered in both places with the tripwire updated, appears in `PARITY.md`, and
`make compile` plus `make drift` are clean. Say which route number it is
(`N/45`) and what you deliberately did not carry across.
