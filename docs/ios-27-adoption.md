# iOS 27 adoption plan

What iOS 27 / Xcode 27 makes possible for this app specifically, ranked by what
it is worth against what it costs. Written against the app as it stands at
commit `1d8148a`.

## The standing rule this plan obeys

Commit `aff809c` removed two iOS 26 API calls — `.tabBarMinimizeBehavior` and
`.glassEffect` — because they had been written from memory rather than checked
against an SDK, and a wrong name or signature fails the whole target. That rule
holds here.

**Nothing in this document has been compiled.** Every API name below comes from
Apple's own release material and should be treated as a pointer to the right
documentation page, not as code to paste. Each item names what to verify in
Xcode 27 before anything lands in the target. The pattern that worked for the
iOS 26 adoption applies again: the parts that are *subtraction* (raising the
deployment target, deleting overrides, deleting a dependency) are safe to do
without a Mac in reach; the parts that *add* a call are not.

## Where the app actually is

Worth stating plainly, because two of these are not what the README says:

| | Reality | Where |
|---|---|---|
| Deployment target | **iOS 26.0** | 6 build configurations |
| Swift language mode | **5.0** | `SWIFT_VERSION = 5.0`, ×6 |
| Strict concurrency | **not set** | no `SWIFT_STRICT_CONCURRENCY` anywhere |
| App source | 141 Swift files, ~65k lines, one target | `Riverhead NY Budget App/` |
| Third-party SDKs | **none** — zero package references, empty Frameworks phases | `project.pbxproj` |
| AI assistant | BYOK OpenAI Responses API, `gpt-5-mini` | `RiverheadAIService.swift`, `OpenAIKeychain.swift` |
| "ML" | hand-calibrated deterministic scorers | `BudgetNeuralNetwork.swift`, `BudgetRLTrainer.swift` |
| CI | **GitHub Actions build + unit + UI tests** | `.github/workflows/ios.yml` |

Three things fell out of establishing that. Two are fixed in the same commit as
this document; the third is the cheapest valuable change on the whole list.

**Fixed: the README described an app that no longer exists.** It claimed "Swift
6, SwiftUI (iOS 18.5+ deployment target)" and "Firebase Analytics (usage
analytics only — no ad SDK)". The target is 26.0, and Firebase was removed
deliberately — `Riverhead_NYApp.swift` says so, `SettingsView` tells the user
"no analytics at all — nothing to opt out of", and there is no Firebase package
reference, no `import Firebase`, and no `GoogleService-Info.plist` anywhere.

**Fixed: three artifacts of that removal were still in the repo.**
`project.xcworkspace/xcshareddata/swiftpm/Package.resolved` still pinned thirteen
packages including `firebase-ios-sdk` and
`google-ads-on-device-conversion-ios-sdk`, and `Info.plist` still carried two
inert `GOOGLE_ANALYTICS_*` keys with a comment describing a Settings opt-out that
no longer exists because there is nothing to opt out of. None of it did anything
— but an app whose product is "no ads, no tracking, check our work" should not
ship a lockfile pinning a Google ads-conversion SDK for a reader to find.

**Open: 72 files carry a `Swift 6 / iOS 17+` header comment, and the project
builds in Swift 5 mode.** 81 files use `@MainActor`, so the concurrency
annotations are there, but none are being *enforced* — the compiler is not
checking data-race safety. Either the headers are aspirational or the build
setting is stale, and it is worth knowing which before layering an async
framework like Foundation Models on top. It needs no iOS 27 API at all: flip
`SWIFT_VERSION` to 6.0 on a branch, see what the compiler says, and decide.

---


## Implemented in the 2026-09-27 parity pass

- The 54-route parity catalog now uses the verified iOS 27 `toolbarMinimizationBehavior(_:for:)` API with `.onScrollDown` for the navigation bar, guarded by `#available(iOS 27.0, *)` so iOS 26 remains supported.
- Building with Xcode 27 automatically benefits from SwiftUI's new lazy class initialization for `@State` and the updated content-builder implementation; no compatibility shim is needed in app code.
- The app keeps system-provided materials and navigation styling rather than replacing them with custom UIKit appearance proxies, preserving the current platform look.

## 1. Foundation Models — the highest-value change available

**What iOS 27 adds.** The framework now reaches any model through a single
`LanguageModel` protocol: Apple's on-device model, Apple models on Private Cloud
Compute, a model you bundle yourself, or an external provider such as Claude or
Gemini — same call site. It also gains multimodal prompts (images alongside
text), Vision tools the model can call on-device (OCR, barcode), and Dynamic
Profiles for swapping model, tools and instructions inside a live session.

**Why it matters here more than for most apps.** Three reasons, in order:

1. **The API key goes away.** `AskAIView` today is gated behind a user pasting
   an OpenAI key into the Keychain. That is a wall almost no resident will climb.
   An on-device model has no key, no account, no per-query cost, and works with
   the plane in airplane mode — which is the same posture as the rest of the
   app, where the budget PDFs and payroll CSVs are already bundled for offline
   use. The assistant stops being a power-user feature.
2. **It is free at this app's scale.** App Store Small Business Program members
   whose apps are under 2M first-time downloads get the next-generation Apple
   models on Private Cloud Compute at no cloud API cost. That covers this app
   comfortably, and it means the hard questions can escalate off-device without
   anyone paying per token.
3. **Privacy actually matters for this one.** A resident asking "what would my
   tax bill be at this assessment" is handing over something about their own
   property. Today that prompt leaves the device for OpenAI. On-device, it does
   not leave at all.

**The change that is worth more than the model swap: tools instead of a fact
pack.** `RiverheadAIService.buildInstructions` currently flattens the app's
knowledge into a prose "fact pack" inside the system instructions — document
years, featured funds, accounting-standards guidance — and hopes the model
repeats the numbers correctly. That is the weakest link in the whole app: the
one place where a figure on screen is not traceable to a source document.

Foundation Models' tool calling inverts it. Rather than pre-loading facts, you
expose the app's own data as tools the model calls when it needs them:

- look up a supplement line by account (`SupplementData.swift`)
- look up a program's full cost and recovery (`ProgramBudgetData.swift`)
- look up a payroll record or title (`payroll-records.json`, `titles-by-year.json`)
- look up a meeting's resolutions and votes (`MeetingsStore.swift`)
- look up a fund balance or reserve figure

Paired with guided generation — a typed struct as the response shape rather than
free text — the answer comes back with a source field the app can *render as a
citation and verify*, instead of a paragraph that may or may not be right. The
web app's own guardrail ("every AI-generated claim should eventually include
source, timestamp, calculation, and confidence" — `web/README.md`) stops being
an aspiration and becomes a type.

**Effort.** Medium-large. New service alongside `RiverheadAIService`, a tool per
dataset, a response type, and `AskAIView` needs a path for "on-device model
unavailable on this device" (older hardware, Apple Intelligence off).

**Risk.** Low to the rest of the app — it is additive and the OpenAI path can
stay as a fallback for one release. The real risk is a small on-device model
being worse at this app's domain than `gpt-5-mini`, which is exactly what item 2
is for.

**Verify in Xcode 27 before writing any of it:** the session type and its
initialiser; how tools are declared and what their argument/return types must
conform to; the guided-generation macro or protocol and which types it accepts;
the availability check for "is a model usable on this device right now"; the
context-window limit and what happens when a prompt exceeds it; and the exact
shape of the `LanguageModel` protocol if you want the provider to be swappable.

---

## 2. The Evaluations framework — the one this app arguably needs most

**What iOS 27 adds.** A Swift framework for quantifying model accuracy as you
iterate, so a prompt change can be measured statistically rather than
eyeballed — unit tests for model quality.

**Why it matters here.** This app's failure mode is not a crash. It is
confidently stating a wrong budget number to a resident who then repeats it at a
public hearing. That is the reputational risk that the Accuracy Watchlist, the
source trail, the "this app does not infer agenda items" framing and the
disclaimer all exist to manage — and the assistant is currently the one surface
with none of that protection.

An eval suite makes the assistant accountable to the same standard as the rest
of the app: a fixed set of questions with known-correct answers drawn from the
bundled data — 2026 adopted appropriations, Public Safety's full cost, the CPF
transfer-tax rate, the 2% tax cap, who voted against a given resolution — scored
on every prompt or model change. It is also the only honest way to answer "is
the on-device model good enough to replace `gpt-5-mini` here?", which is the
open question item 1 leaves behind.

The ground truth already exists and is already tested: `programs.json`'s
reconciliation, the supplement datasets, the meeting vote records, and the 18
tests added in `1d8148a`.

**Effort.** Small-to-medium, and it pays for itself the first time it catches a
regression.

**Risk.** None to shipping code — it lives in the test target.

**Verify:** whether it ships in Xcode 27 as a framework, an SPM package or an
open-source repo; how a suite is declared and run; and whether it can run in CI
without a Mac in the loop (relevant, since this repo has no CI at all — see
item 8).

---

## 3. App Intents and App Schemas — the distribution win

**What iOS 27 adds.** Entity schemas contribute an app's content to the
Spotlight *semantic* index, so Siri can surface it with attribution back to the
app. Intent schemas let people act on that content in natural language with no
phrases to define and no code change as Siri's language understanding improves.
A View Annotations API maps views to entities so people can reference what is on
screen conversationally. An App Intents Testing framework validates the whole
integration through real system pathways, without UI automation.

**Why it matters here.** This is a civic app whose problem is that residents
don't know it exists at the moment they need it. Someone wondering when the next
Town Board meeting is does not open a budget app — they ask Siri or type in
Spotlight. Semantic indexing puts the answer there, with attribution back to the
app.

The app already has the entities, sitting in decoded structs:

| Entity | Source | What Siri could answer |
|---|---|---|
| Town Board meeting | `MeetingsStore.swift` | "When's the next Riverhead Town Board meeting?" |
| Resolution + roll call | `MeetingDetail` | "How did the Riverhead board vote on 2026-814?" |
| Program / service | `ProgramBudgetData.swift` | "What does Riverhead spend on police?" |
| Department | `ProgramBudgetDepartment` | "What's Riverhead's code enforcement budget?" |
| Budget account line | `SupplementData.swift` | — |
| Payroll title | `titles-by-year.json` | "How many Riverhead employees are crossing guards?" |

The meeting entity is the one to do first, because it is the most time-sensitive
thing the app knows and the one a resident most needs *before* the fact. It also
pairs directly with item 4.

One caution specific to this app: the meetings data carries hard-won
distinctions — held vs. minutes published vs. vote record published; published
agenda vs. official hearing notice. A Siri answer that flattens "no vote record
yet" into "no votes" would undo exactly the care taken in commit `7330b6e`. The
entity's display representation has to carry the state, not just the date.

**Effort.** Medium per entity, small after the first.

**Risk.** Low. Additive, and the testing framework means it can be verified
without hand-driving Siri.

**Verify:** which App Schemas categories exist and whether any fits a civic or
reference-data app; `IndexedEntity` conformance and the indexing call;
`@Property(indexingKey:)`; `IntentValueQuery` for the large sets (payroll,
account lines); and whether View Annotations is worth it before the entities
exist.

---

## 4. WidgetKit — the app has an obvious widget and doesn't ship one

**What iOS 27 adds.** Widget customisation through App Intents and dynamic
styling, on top of the refreshed system materials.

**Why it matters here.** "Next Town Board meeting" is a widget-shaped fact: one
date, one time, a count of published agenda items, and — after `7330b6e` — an
honest state for a meeting that has been held but has no roll call yet. The data
is bundled, so the widget needs no network and no background refresh beyond a
timeline of known dates. `upcoming.json` now carries the Board's adopted
calendar, which is exactly a widget timeline.

A second candidate: a tax-bill widget pinned to the assessment a resident
entered in `MyTaxesView`, showing what the current levy means for them.

App Intents configuration is what makes it worth doing now rather than in iOS
26 — the resident picks which meeting type, or which of their saved scenarios,
from the widget's own edit sheet.

**Effort.** Medium — a widget extension is a new target, which also means
deciding what moves into a shared framework or gets duplicated. `MeetingsStore`
and its JSON would need to be reachable from the extension.

**Risk.** Low, contained in a new target.

**Verify:** the App Intents configuration API for widgets; what "dynamic
styling" covers; and the current `TimelineProvider` shape.

---

## 5. SwiftUI lazy stacks with prefetching — free performance on the worst screens

**What iOS 27 adds.** `LazyVStack`/`LazyHStack` estimate sizes, load subviews
lazily and prefetch content ahead of the scroll. Plus reordering APIs that work
with any container, toolbar visibility priority, swipe actions on any view, and
lazy state initialisation for `Observable` types.

**Why it matters here — with a caveat worth stating up front.** The app bundles
six years of gross-earnings CSVs (400–800 KB each) plus a per-account supplement
ledger, and the long screens over them are the obvious candidates:
`SupplementLineExplorerView`, `GrossEarningsNewsdayView`, `WorkforceByTitleView`.

But all three of those use `List`, not a lazy stack — and `List` already
recycles rows. The prefetching improvement is specifically a `LazyVStack` /
`LazyHStack` feature, so this is **not** a free win by swapping one symbol for
another. Treat it as "profile the payroll screens first, and only move to a
`ScrollView` + `LazyVStack` if `List` is measurably the problem." Assuming
otherwise is how a performance change makes things slower.

The parts of the SwiftUI release that *do* apply without a measurement first:

- **Reordering APIs that work with any container.** The Spending Reduction
  toggle list and Saved Scenarios both present a set the user is actively
  working with, and neither can be reordered today.
- **Swipe actions on any view.** Several of these screens present rows inside
  cards rather than `List` rows, which is exactly where swipe actions were
  previously unavailable.
- **Lazy state initialisation for `Observable` types.** Relevant to the stores
  injected through the environment (`RBBudgetStore`, `RBCivicToolkitStore`,
  `RBSixSigmaStore`) if any of them do real work at init.

**Effort.** Small per screen once measured.

**Risk.** Low, but the risk is wasted effort rather than breakage.

**Verify:** the prefetch API's name and whether it is opt-in; whether any of it
reaches `List`; the reordering API's shape.

---

## 6. NowPlaying framework — attractive, but it does not apply as-is

**What iOS 27 adds.** A framework connecting an app's playback to the Lock
Screen, Control Center, Dynamic Island and CarPlay.

**Why it looked like a fit.** `Channel22View` carries the Town's own
government-access channel. A resident listening to a three-hour board meeting
cannot pause it from the Lock Screen or hear it in the car — which is exactly
how people consume meeting video.

**Why it does not apply yet.** `Channel22View` is a `WKWebView` wrapping the
Town's own embedded player, not an `AVPlayer`. NowPlaying connects *an app's
playback* to the system, and this app does not own the playback. Adopting it
means first replacing the web embed with a native player pointed at the
underlying stream — a much larger change that also raises a question this app
should answer deliberately rather than incidentally: whether re-hosting the
Town's video feed outside its own player is something the Town's provider
permits, and whether an independent app should be doing it at all.

**Recommendation.** Park it. If native playback is ever wanted for its own
sake, NowPlaying is the reason to finish the job — but it is not itself the
reason to start.

---

## 7. Design System — finish what the iOS 26 commit started

**What iOS 27 adds.** Unified materials and typography across platforms,
updated tab and navigation bars, refreshed materials, refined typography.

**Why it matters here.** Commit `aff809c` deliberately stopped at the
subtraction half of the iOS 26 adoption — deployment target raised, UIKit
appearance proxies deleted, `toolbarBackground` overrides removed — and left
`.glassEffect` and `.tabBarMinimizeBehavior` out because they could not be
compiled. On a machine with Xcode 27 those two lines are a ten-minute job, and
the startup banner in `MainTabView` still carries the comment saying so.

The six hand-rolled `GlassCard` structs (one per view file, including the one
added in `1d8148a`) are the other half. If iOS 27's materials make a card look
right with less hand-drawn border and shadow, that is six near-duplicates
collapsing into one shared component.

**Effort.** Small, but only meaningful in front of a simulator.

**Risk.** Visual. Needs eyes, not reasoning.

---

## 8. What is *not* worth doing

**Core AI, for now.** Core AI loads and runs your own models on-device via the
`.aimodel` format with ahead-of-time compilation, and it is a genuinely good
framework. It is tempting to point it at `BudgetNeuralNetwork.swift` and
`BudgetRLTrainer.swift` — but read what those files say about themselves: "hand
-calibrated inference models, not live-trained networks", and "a deterministic,
local contextual-bandit pass". There is no trained model to port and no training
set to make one from. Converting a deterministic scorer into a neural network
would make the app's signal ranking *less* explainable, not more, and
explainability is this app's entire product. Revisit only if a real labelled
dataset appears.

**Multimodal prompts, for now.** Image input is the headline Foundation Models
feature and the obvious pitch is "photograph your tax bill". It is worth
resisting until item 2 exists: OCR'ing a resident's own tax bill and reasoning
about it is the highest-stakes thing this app could do, and it should not ship
without an eval suite behind it. The Vision OCR tools will still be there later.

**Anything requiring CI.** This repo has no `.github/workflows` and no Swift
toolchain in the remote session, so every change here is verified on someone's
Mac by hand. That is the real constraint on all of the above, and it is worth
fixing before the list gets longer — even a single `xcodebuild build` job on a
macOS runner would end the class of problem that `aff809c` had to clean up.

---

## Suggested order

| | Item | Why here |
|---|---|---|
| 1 | Swift 6 language mode | Costs nothing, decides what the concurrency annotations mean, and needs doing before async framework work |
| 2 | CI: one build job | Ends the "written from memory, never compiled" failure mode |
| 3 | ~~README platform correction~~ | Done alongside this document |
| 4 | Evaluations suite against the current OpenAI assistant | Establishes the accuracy baseline *before* the model changes |
| 5 | Foundation Models with tool calling | The main event; now measurable against 4 |
| 6 | App Intents: meeting entity | Biggest reach for the effort |
| 7 | Widget: next meeting | Reuses 6 |
| 8 | Lazy stacks on the payroll screens | Independent; do whenever |
| 9 | Design System finish (`.glassEffect`, `.tabBarMinimizeBehavior`, shared card) | Small, visual, needs a simulator |

Items 1–4 need no iOS 27 API at all, which is the point: the most valuable work
on this list is available before a single new symbol is typed.

## Sources

- [What's New in iOS 27 — Apple Developer](https://developer.apple.com/ios/whats-new/)
- [WWDC26: What's new in the Foundation Models framework](https://developer.apple.com/videos/play/wwdc2026/241/)
- [WWDC26: Build intelligent Siri experiences with App Schemas](https://developer.apple.com/videos/play/wwdc2026/240/)
- [WWDC26: Explore advanced App Intents features for Siri and Apple Intelligence](https://developer.apple.com/videos/play/wwdc2026/343/)
- [WWDC26: Dive into lazy stacks and scrolling with SwiftUI](https://developer.apple.com/videos/play/wwdc2026/321/)
- [Core AI — Apple Developer](https://developer.apple.com/core-ai/)
- [WWDC26 Machine Learning guide](https://developer.apple.com/wwdc26/guides/machine-learning/)
- [WWDC26 Apple Intelligence guide](https://developer.apple.com/wwdc26/guides/apple-intelligence/)
