# Riverhead NY Budget App

An independent public fiscal intelligence app for exploring Riverhead Town budgets, taxes, payroll, campaign finance, capital projects, and civic accountability tools — built for iOS using publicly available Town and New York State records.

## Get the App

### ▶ **[Riverhead NY Budget App on the App Store](https://apps.apple.com/us/app/riverhead-ny-budget-app/id6751372951)**

An Android release is in progress — see `AndroidFork/` in this repo for the in-progress native port.

GitHub Repository:
https://github.com/rike4545/Riverhead-NY-Budget-App

Also available on the web:
**[Riverhead Budget Live](https://rike4545.github.io/rike4545-riverhead-budget-live/)** — the browser-based companion platform, covering much of the same ground plus live campaign-finance data and peer-town benchmarking. Repo: https://github.com/rike4545/rike4545-riverhead-budget-live

---

# What's New

This release reconciles the app's own 2027 budget models into one consistent set of
numbers and makes the resulting savings package interactive.

### ✂️ 2027 Spending Reduction
A dedicated, toggleable view of every real, individually-sourced recurring
spending-reduction candidate identified for the 2027 budget — not a wishlist:

- Six personnel/policy categories (healthcare contribution policy, overtime
  recovery, targeted retirement/refill control, civilian vacancy factor,
  exempt/elected raise holds) plus real account-level operational growth
  flagged in the 2026 Budget Supplement
- Every item is tappable, with a live running total and a coverage bar against
  the modeled 2027 payroll-pressure gap
- The Police Uniform OT recovery target is benchmarked against a comparable
  peer town's per-officer overtime rate rather than assuming the full
  budget-vs-actual variance is recoverable
- Explicitly excludes contractually-locked PBA/SOA/CSEA union wage growth,
  with a note on why those figures are likely to remain placeholders through
  the 2027 budget cycle (both contracts expire 12/31/2026; New York routes
  police/fire bargaining impasses to binding arbitration, not legislative
  resolution)

### 🔧 Reconciliation fixes
Three previously-inconsistent 2027 planning views (the Budget Hub, the 2027
Simulator, and the Executive Whiteboard) used to disagree with each other on
the same "recurring savings" and "payroll pressure" figures by as much as
$12,000. All three now compute from one shared, canonical source of truth.

### 🚫 No ads
Removed Google AdMob entirely — no banner ads, no ad-network SDK, no App
Tracking Transparency prompt.

---

# What Is This App?

Use this app to explore public budget, tax, campaign-finance, procurement,
project, payroll, pension, contract, and civic-oversight information about
the Town of Riverhead — organized into easier-to-read views that link back to
the official source material.

The app helps residents, taxpayers, and civic-minded users better understand:

- where public money comes from and where it goes
- what a resident's own property tax bill is built from
- how reserves, fund balance, and debt affect future budgets
- how departmental spending and payroll evolve year over year
- who funds Town Board campaigns
- procurement exceptions and sole-source contracts
- what's actually in a Town Board meeting's fiscal-impact statement
- how to prepare sourced questions before a public hearing

It does **not** replace any official Town communication channel, provide
legal/financial/emergency advice, or modify any Town, State, or third-party
data — see **Important Disclaimer** below.

---

# Core Features

The app is organized into five tabs: **Home**, **Budget**, **Civic**, **Tools**, and **More**.

## Budget
- **Overview** — resident/expert audience toggle, headline budget summary.
- **My Taxes** — personal property-tax impact view.
- **2027 Planning** — Budget Message (unofficial proposal), Early Retirement
  Model, Executive Summary, Budget Lab (scenario controls), Budget Simulator,
  and **Spending Reduction** (see What's New above).
- **Evidence & Detail** — Supplement Explorer, Outlier detection, Employees
  (payroll), Glossary.
- **Public Review** — Hearing Toolkit, Capital & Debt, Fund Balance, Tax
  Impact — each with sub-views for reserve trends, peer-town benchmarking,
  and historical fund-balance detail.

## Civic (Command Center)
A searchable, task-oriented hub grouped by what you're trying to do:
- **Accountability** — Town Board Scorecard, campaign donations, procurement
  exceptions, Petrocelli/Town Square watch.
- **Budget & Taxes** — where the money goes, tax-bill construction, reserve
  levels, 2027 pressure.
- **Town Projects** — the Petrocelli hotel deal: public land, costs, contract
  terms, open questions.
- **Resident Toolkit** — build sourced questions and testimony before a
  hearing; source-trail lookup before repeating a number or claim.
- **Find & Export** — search and saved scenarios.

## Tools
- Town Board Scorecard, Campaign Donation Ethics, Procurement Watch
- Employee Pay Lookup (public gross-earnings data, 2018–2023)
- Budget Explainers, Budget Policy Insights
- Contract Cost Increases / Contract Cost Estimator
- Department Spending Forecast, Snow Removal Overtime
- Capital Projects Map, Town Departments directory, Channel 22 (Town TV)
- Cost of Living Guide, Public Speech & Legal Risk, Efficiency Analysis (Six Sigma)

## More
About, Ask AI, Settings, Search, Saved Scenarios, plus additional
accountability and budget tools: Retirement Waivers (NY), Roads Dashboard,
Snow Budget Overrun, Town Salary Comparison, Officials & Pensions, News &
Events, PDF Search, Town Code (eCode360), Contract Raise View, Department
Spend Forecast, Defamation Risk Analysis, Plurality & Oversight, Council
Scorecard.

---

# Important Disclaimer

This app is not produced by, affiliated with, or endorsed by the Town of
Riverhead, its officials, or its departments. It does not replace any
official Town communication channel and does not provide legal, financial,
or emergency advice. It cannot guarantee that source data is accurate,
complete, current, or interpreted the same way an official agency would
interpret it.

This app is not endorsed by, financed by, affiliated with, or produced on
behalf of any political campaign, candidate, political party, political
action committee, or elected official. It is an independent, community-built
civic tool. No candidate or campaign has paid for, directed, or approved any
content in this app.

For official information, always rely on the original agency source or
direct contact with the responsible government office —
[townofriverheadny.gov](https://www.townofriverheadny.gov).

---

# Data Sources

This project uses publicly available Town financial records and New York
State open data, including:

Town of Riverhead Financial Reports:
https://www.townofriverheadny.gov/206/Financial-Reports

Examples include Adopted Budgets, Budget Supplements, Annual Financial
Reports, Audited Financial Statements, published payroll/gross-earnings
data, and New York State Board of Elections campaign-finance disclosures.

---

# Technology

Built using:

- Swift 6, SwiftUI (iOS 18.5+ deployment target)
- `@Observable` / `ObservableObject` state stores injected via environment
- Firebase Analytics (usage analytics only — no ad SDK)
- Local CSV/PDF assets bundled for offline-first budget and payroll data

---

# Repository Layout

```text
Riverhead NY Budget App/       Main SwiftUI app target (views, models, stores)
Riverhead NY Budget AppTests/  Unit tests
Riverhead NY Budget AppUITests/ UI tests
AndroidFork/                   In-progress native Android port (Kotlin + Jetpack Compose)
```

See `AndroidFork/README.md` for the Android port's current status.

---

# Status

Under active development. Recent focus has been reconciling the 2027 budget
planning models into one consistent source of truth and building interactive
tools (Spending Reduction, Budget Simulator) on top of it.
