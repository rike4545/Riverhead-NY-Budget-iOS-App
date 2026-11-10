## Web parity drift

0 breaks, 1 drift, over 15 of 15 endpoints.

### Drift

The view still renders, but it no longer agrees with the web app.

| route | where | what |
| --- | --- | --- |
| `/tax-bill/` | `lookup` | the web app publishes this but `TaxBillParityDocument` has no property for it, so the view ignores it |

### Notes

Nothing to do.

| route | where | what |
| --- | --- | --- |
| `/candidate-watch/` | `races[].candidates[].party` | CandidateParty.spelledOut(_:) and .tint(_:) in CandidateWatchParityView.swift handles "R", "C", which no longer appears in the data |

