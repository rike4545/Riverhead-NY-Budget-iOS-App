# Agents

Seven agents, each a role rather than a task. Reach for one by what you are
trying to do:

| you are… | agent |
| --- | --- |
| porting another web route to native SwiftUI | `parity-route-porter` |
| about to push Swift and cannot run `make compile` | `swift-ci-gatekeeper` |
| looking at the same code copied across many files | `swift-duplication-surgeon` |
| improving how a screen looks, or auditing accessibility | `swiftui-ux-reviewer` |
| reacting to a parity drift finding, or a native screen showing its web fallback | `web-parity-watchdog` |
| checking a budget, tax or fund-balance figure is right and fairly framed | `riverhead-domain-expert` |
| working on Core ML, Vision, Swift Charts, or the BYOK AI features | `ios-ml-expert` |

They are deliberately few and sharply scoped. Agents overlap badly when they
are defined by topic ("the Swift agent", "the data agent") and well when
defined by the decision they own, so each one here answers a different
question: *does this compile*, *is this the same code twice*, *does this
screen adapt*, *has the web app moved*, *is this number honest*.

Two of them pair up rather than compete: `web-parity-watchdog` decides what a
changed payload should mean on screen, and `parity-route-porter` brings a new
route across. Run the gatekeeper before any push that touches Swift in a
session without Xcode.

Every number quoted inside these files was measured, and each includes the
command to re-measure it. Re-run those rather than trusting the figure — the
whole point of the parity work is that a second copy of a fact goes stale.
