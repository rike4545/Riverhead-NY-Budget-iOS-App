# Riverhead NY Budget App (iOS): notes for Claude

A SwiftUI app about the Town of Riverhead, NY's budgets, taxes, payroll, debt
and Town Board decisions, on the App Store. Its readers are residents, and every
figure in it has to trace to an official record. The website
(rike4545/Riverhead-NY-Budget-Web-App) is the source of truth: when a figure
here disagrees with the website, the website's data and `web/lib/` are right.

## Layout

- `Riverhead NY Budget App/`: all Swift sources and bundled JSON. The project
  uses a file-system synchronized group, so a new file in this folder is in the
  build with no `project.pbxproj` edit.
- `Riverhead NY Budget AppTests/`: unit tests in Swift Testing
  (`@testable import Riverhead_NY_Budget_App`).
- `Riverhead NY Budget AppUITests/`: UI tests. They tap the tab titles "Home",
  "Budget", "Civic", "Tools" and "More"; don't rename them.
- `BudgetLiveParityView.swift`: the catalog of every website page (91 entries
  as of November 12, 2026). `PARITY.md` records how it tracks the website.
- `.github/workflows/`: `ios.yml` (build, unit and UI tests on macOS),
  `parity-drift.yml` (live website data against the Swift decoders) and
  `sync-web-data.yml` (daily copy of shared datasets from the website).
- `.claude/agents/`: seven agents; `.claude/agents/README.md` says which to use.
- `web/` here is an old prototype, not the website.

## Commands

```bash
make compile   # app and both test bundles, no simulator: run before committing
make check     # compile, then the unit tests on a simulator
make ui        # UI tests (slow)
make drift     # live website data against the Swift decoders (node only)
```

The `make` targets need Xcode. A cloud session has none, so CI is the compiler
there: push to a draft PR and read the checks. `make drift` and
`make drift-test` need only node and run anywhere.

## Rules

- Work on the branch the session gives you and open draft pull requests. Never
  merge and never push to `main`: the owner merges.
- This repo is private, so CI bills Actions minutes, and macOS minutes count
  ten times. Compile locally when you can, and don't re-run CI without a
  reason. A job that ends in seconds with no runner means the account's minutes
  or spending limit ran out, not that the code failed.
- Swift 5 language mode, with no default actor isolation.
- Don't hand-edit `supplement-lines.json`, `supplement-outliers.json`,
  `reductions.json`, `payroll-records.json` or `titles-by-year.json`. The daily
  sync overwrites them from the website, whose `shared-data/manifest.json`
  lists them.
- Commit messages and pull requests say what changed and why, in prose.

## Accuracy

- Quote a figure from its record and cite it in the copy. Leave it blank rather
  than guess, and say why.
- Hard-coded figures go stale. When the Town publishes a newer record (an
  audit, a budget stage), search the Swift sources for the old figure and update
  every copy. Example: the 2025 audit (accepted September 1, 2026, Resolution
  2026-834) gives unassigned General Fund balance as $28,829,513. The unaudited
  Annual Financial Report's figure was $29,671,084.
- The Town's fund-balance policy is Resolution 918 of 2011: a 15% floor and no
  ceiling. A 20% line is the app's reference point, never Town policy.
- Frame findings as likely concerns for residents, not legal or audit
  determinations. Keep machine transcripts and unofficial results labelled.
- Never put personal email addresses, keys or tokens in code or data.
