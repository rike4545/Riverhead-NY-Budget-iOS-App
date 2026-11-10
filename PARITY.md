# Riverhead Budget Live → iOS parity

This document defines parity against the current user-facing navigation in
`Riverhead-NY-Budget-Web-App/web/components/SiteNav.tsx`.

## Current parity layer

`BudgetLiveParityView` exposes every current web navigation destination inside
the iOS app. The catalog contains **87 entries** across the same five
navigation groups used by the web product:

- Start Here — 4
- Explore — 26
- Government — 21
- 2027 & Analysis — 26
- Evidence — 10

The Budget tab exposes this catalog from the navigation bar. The catalog now matches the current web SiteNav exactly (87 entries over 87 distinct routes and 86 distinct pages, as of 2026-11-10; the workforce page carries two entries, the roster and the organization chart anchored inside it). A drift check compares the table against the live navigation on every pull request, so it no longer takes an audit to notice a new route, including Revenue, Fund Balance Draws, Management Pay, Police Spending & Crime, School Resource Officers, Supervisor’s Promises, Open Meetings Law, 2027 Tentative Budget, and Budget Adoption. On 2026-11-07 it added nine pages the web app had gained: Preserved Land and Transfer of Development Rights (Explore); Election Map, Donation Map and Board Votes (Government); and Budget Flow, Assessment Roll, Legal Costs and Regional CPF Counsel (2027 & Analysis). All nine open as web fallbacks. On 2026-11-08 it added Grants (Explore) and State of the Town Addresses (Government), also as web fallbacks, and then Comprehensive Plan Tracker (Explore). On 2026-11-10 it added How the Town's Books Work, the Fiscal Impact Statement Helper, Department Efficiency and Supervisor's Office Pay Compared, all as web fallbacks. The same day the website's Fiscal Impact page gained a section on statements that contradict themselves; the route is a web fallback, so the app shows it unchanged. Routes with a
verified native counterpart open SwiftUI directly; every other destination uses
the existing `WebContentView` / `WKWebView` implementation and therefore keeps
loading the current GitHub Pages version until its native replacement is ready.

This is **complete functional access parity**, not a claim that all 86 pages
have already been rewritten as native SwiftUI screens.

The drift check reported two routes unreachable — not even as a web fallback.
`/records/` was closed by PR #25 on 2026-10-27, which also removed a duplicate
`/tentative-2027/` entry. That duplicate had been breaking two assertions in
`BudgetLiveParityTests` — `routeCount == 62` against an actual 63, and
`hasUniquePaths` — which is how it went unnoticed.

`/rvac-funding/` (Ambulance Funding) was still missing and is added here, in
Explore, where the web nav puts it. Its title mirrors the nav label rather than
the page heading, which is the rule the catalog follows; the same rule is why
the `/records/` entry is titled "Records the Town Has Not Published" (the nav
label) rather than "Records to Request" (the page's H1), changed here from what
PR #25 shipped.

## Native routes in the parity hub

16 of 86 pages render natively. This list is generated from
`BudgetLiveParityCatalog.nativePaths` and the `parityDestination` switch; it
went twelve routes stale once, so update it in the same commit that adds a
route.

- `/tax-bill/` → `NativeTaxBillParityView` — My Taxes
- `/payroll/` → `NativePayrollParityView` — Payroll
- `/road-spending/` → `NativeRoadSpendingParityView` — Road Spending
- `/town-history/` → `NativeTownHistoryParityView` — Supervisors & Council History
- `/officials/` → `NativeOfficialsParityView` — Officials & Pensions
- `/candidate-watch/` → `NativeCandidateWatchParityView` — Candidate Watch
- `/tax-cap/` → `NativeTaxCapParityView` — Tax Cap
- `/search/` → `NativeUnifiedSearchView` — Search
- `/meetings/` → `TownBoardVotesView` — Board Votes
- `/funds/` → `FundDetailExplorerView` — Budget Overview
- `/programs/` → `NativeProgramBudgetView` — Program Budget
- `/compare/` → `NativeBudgetCompareView` — Budget Compare
- `/general-fund/` → `NativeGeneralFundHistoryView` — General Fund
- `/workforce-by-title/` → `WorkforceByTitleView` — Workforce by Title
- `/board-elections/` → `NativeBoardElectionsParityView` — Board Elections
- `/outliers/` → `NativeOutlierWatchView` — Outlier Watch

The later routes follow one pattern: fetch the web app's own published JSON
over HTTPS, decode it, render natively, and fall back to the live page if the
fetch fails. Nothing restates the web app's content in Swift, so the two
cannot drift. Where a page's content lives only in its TypeScript markup
rather than in a published file, that is recorded in the route's own source
as either mirrored or deliberately omitted.

Cards come from `riverheadCard()` in `RiverheadCard.swift`, not per-file
copies; radii come from `RiverheadTheme.Radius`.

## Existing native coverage

The iOS repo already contains substantial native equivalents, including:

- My Taxes / tax-impact tools
- payroll and workforce explorers
- Town Board votes and fiscal-impact data
- fund and department explorers
- General Fund history data
- reserves / fund balance
- capital, debt, BAN, and Town Square tools
- road spending
- Community Preservation Fund
- 2026 buyout / early-retirement analysis
- officials and pensions
- Board Elections
- campaign contributions
- Candidate Watch and candidate cost-benefit analysis
- 2027 prediction/scenario/simulator/spending-reduction tools
- credit rating
- outlier and budget-accuracy analysis

Those native screens remain the preferred iOS experience where they fully match
the web feature. The live parity catalog is the safety net that guarantees a web
feature is never simply missing from iOS.

## Shared-data contract

The web repo is already the canonical producer for a subset of data used by the
native app. `shared-data/manifest.json` currently mirrors:

- all meeting/fiscal-impact JSON files and indexes
- budget supplement lines
- budget supplement outliers
- budget reduction candidates
- payroll records
- payroll titles by year

The existing `scripts/sync-shared-data.mjs` workflow verifies copied files by
SHA-256. Native parity work should extend this contract instead of introducing
new hand-maintained copies of web data.

For computed datasets that are better served live than bundled, the preferred
pattern is a versioned static JSON contract generated from the same web module
that renders the page. Program Budget is the first use of this pattern.

## Staying in parity once a route is native

A native parity view fetches its JSON, decodes it, and falls back to
`WebContentView` if anything throws. That fallback is why web-side drift is
invisible: no crash, no log, the native screen just stops appearing. It has
already happened once, on `/tax-bill/`.

Two things run on their own:

- `sync-web-data.yml` pulls the canonical bundled datasets daily.
- `parity-drift.yml` checks the **live** published payloads against what the
  Swift decoders actually require, on every pull request and once a day, and
  opens a draft pull request when it finds something.

The contract is derived from the Swift source by
`.github/scripts/parity-schema.mjs`, so there is no second copy to keep in sync
and a new route is covered the day it lands.
`.github/parity-contract.json` adds only what the Swift cannot state itself:
which URL feeds which document, the string values a `switch` handles, and prose
mirrored out of a page's markup.

```
make drift        check the live web data against the Swift decoders
make drift-test   prove the checker still detects (no network)
```

Findings are `break` (the decoder throws — the native view is gone), `drift`
(it renders but disagrees with the web app), or `note`. A fetch that does not
arrive never fails the check.

Work the findings with the `web-parity-watchdog` agent, which decides the part
a script should not: whether a vanished field becomes optional or the view
stops showing it, which new published field earns a row on screen, and what a
new status code means before it gets a colour.

## Drift pass, 2026-11-05

The checker reported `0 break, 12 drift, 1 note`. The other ten findings were
all `unknown-key` — the web app publishes a field and the Swift decoder has no
property for it, so the native view silently ignores content the web route
shows. None was a break; nothing was falling back to a web view. All ten are
now closed and the checker reports **0 break, 0 drift**.

PR #25 had already added the properties for seven of them, which silences the
checker because the schema is derived from the Swift declarations. It wired
none of them to anything: `fields`, `topRaises` and `sha256` were declared and
never read. The table below is what each field now actually does.

Every added property is **optional**, including the ones present on every row
today. A non-optional field that the web later stops publishing throws the whole
document away, and the native screen becomes its web fallback with no crash and
no log — the failure this document already records against `/tax-bill/`.

| Field | Decision |
|---|---|
| `board-elections` `priorElections[].status` | **Shown.** "Unofficial — not yet certified" is published only while a canvass is open. Rendering the vote counts without it states a result more firmly than the Board of Elections has. |
| `board-elections` `priorElections[].turnout` | **Shown**, as a percentage in each cycle's section header. `turnoutNote` already says it in prose; the figure makes six cycles scannable without reading six paragraphs. |
| `fund-appropriations` `funds[].firstYear` / `lastYear` / `totalChange` / `totalChangePct` | **Shown** as a "whole range" line under each flagged fund. This is first-to-last across the published range, a different measure from the year-over-year change the view computes, so it is context rather than a duplicate. |
| `fund-appropriations` `townTotals` | **Shown** in Snapshot — the town-wide baseline a single fund's swing sits against. Read from the document rather than summed from `funds`, so it stays whatever the ETL says the total is. |
| `payroll-records` `fields` | **Shown** under Record notes. `fields["k"]` is the ETL's authoritative order for the `k` array, which `otherComponents` maps to labels *by position*. If the web reorders it, the positional mapping would quietly relabel buy-outs as stipends. |
| `salary-comparison` `summary.topRaises` | **Decoded, deliberately not shown.** `records` already carries every row and the screen sorts the full list by raise or percent. A fixed fifteen is strictly less, and a second ranking on the same screen could disagree with the first after a filter. |
| `search-manifest` `shards[*].sha256` | **Used, not shown.** Shards are fetched with `.returnCacheDataElseLoad`, which on its own serves a cached shard indefinitely. The hash is now the cache key, so a republished index actually arrives. |

### The remaining note is correct and stays

`closed-set-unused` reports that `CandidateParty` handles `"R"` and `"C"`, which
the current data no longer contains. It should keep handling them. The live
payload carries only `"D"` and `"R/C"` because this cycle's Republican ran on a
fused Republican/Conservative line; fusion is not guaranteed, and either bare
code can return at any election. Removing the branches to silence a note would
be a regression that shows a reader `"C"` instead of "Conservative". The note is
doing its job — recording that a branch is currently unexercised, not that it is
wrong.

## Native parity definition of done

A web route is fully native-parity only when the SwiftUI implementation matches
all material behavior of the web route:

1. Same canonical source dataset or API.
2. Same material calculations, totals, filters, sorts, and comparison periods.
3. Same source/freshness/limitation disclosures.
4. Equivalent search and drill-down behavior where the web route provides it.
5. Empty, loading, and error states appropriate for iOS.
6. Automated tests for route-critical calculations and data decoding.
7. No hard-coded duplicate of a value that is already generated by web ETL.

## Highest-priority native gaps to audit/port

The next pass should concentrate first on routes that do not have an obvious
full native equivalent, or whose native data contract may lag the web version:

- Search
- Community Housing Plan
- Supervisors & Council History
- Source Library
- Downloads
- Data Quality & Freshness
- Standards (GFOA)
- Election Law Case
- Officials on Social Media
- Know Your Rights (ICE)

Then audit the existing native implementations of Annual Report, Campaign
Finance, Outlier Watch, Budget Accuracy, and Fiscal Impact against their current
web behavior and canonical datasets.
