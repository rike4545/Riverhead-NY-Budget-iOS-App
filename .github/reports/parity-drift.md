## Web parity drift

0 breaks, 1 drift, over 15 of 15 endpoints.

### Drift

The view still renders, but it no longer agrees with the web app.

| route | where | what |
| --- | --- | --- |
| `/rvac-funding/` | `—` | the web app's navigation offers `/rvac-funding/` and the app's route table does not, so the page is unreachable from the app — not even as a web fallback |

### Notes

Nothing to do.

| route | where | what |
| --- | --- | --- |
| `/candidate-watch/` | `races[].candidates[].party` | CandidateParty.spelledOut(_:) and .tint(_:) in CandidateWatchParityView.swift handles "R", "C", which no longer appears in the data |

