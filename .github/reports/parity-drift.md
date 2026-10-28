## Web parity drift

0 breaks, 9 drifts, over 15 of 15 endpoints.

### Drift

The view still renders, but it no longer agrees with the web app.

| route | where | what |
| --- | --- | --- |
| `/outliers/` | `funds[].firstYear` | the web app publishes this but `OutlierHistoryDocument.Fund` has no property for it, so the view ignores it _(×19)_ |
| `/outliers/` | `funds[].lastYear` | the web app publishes this but `OutlierHistoryDocument.Fund` has no property for it, so the view ignores it _(×19)_ |
| `/outliers/` | `funds[].totalChange` | the web app publishes this but `OutlierHistoryDocument.Fund` has no property for it, so the view ignores it _(×19)_ |
| `/outliers/` | `funds[].totalChangePct` | the web app publishes this but `OutlierHistoryDocument.Fund` has no property for it, so the view ignores it _(×19)_ |
| `/outliers/` | `townTotals` | the web app publishes this but `OutlierHistoryDocument` has no property for it, so the view ignores it |
| `/records/` | `—` | the web app's navigation offers `/records/` and the app's route table does not, so the page is unreachable from the app — not even as a web fallback |
| `/payroll/` | `fields` | the web app publishes this but `PayrollRecordsDocument` has no property for it, so the view ignores it |
| `/salary/` | `summary.topRaises` | the web app publishes this but `SalaryComparisonDocument.Summary` has no property for it, so the view ignores it |
| `/search/` | `shards[*].sha256` | the web app publishes this but `RiverheadSearchManifest.Shard` has no property for it, so the view ignores it _(×7)_ |

### Notes

Nothing to do.

| route | where | what |
| --- | --- | --- |
| `/candidate-watch/` | `races[].candidates[].party` | CandidateParty.spelledOut(_:) and .tint(_:) in CandidateWatchParityView.swift handles "R", "C", which no longer appears in the data |

