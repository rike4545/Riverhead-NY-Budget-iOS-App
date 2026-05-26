# Riverhead Budget Live

Riverhead Budget Live is the web product companion to the Riverhead NY Budget App.

## Goal

Turn the Town of Riverhead budget into a living, public-facing civic intelligence platform with KPIs, charts, budget comparisons, fiscal risk signals, debt modeling, capital project tracking, and BudgetGuard AI validation.

## Phase 1 MVP

- Executive fiscal dashboard
- Historical budget comparison
- Budget variance and change detection
- Fiscal risk monitor
- Debt and BAN simulator
- Capital projects overview
- BudgetGuard AI agent status console

## Guardrails

- Official adopted figures are immutable snapshots.
- AI can flag, explain, reconcile, and recommend.
- AI cannot silently alter official numbers.
- Every AI-generated claim should eventually include source, timestamp, calculation, and confidence.

## Local development

```bash
cd web
npm install
npm run dev
```
