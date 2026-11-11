//
//  Budget2027Status.swift
//  Riverhead NY Budget App
//
//  Where the Town's official 2027 budget stands, for the screens that link to it.
//
//  The Town has published its 2027 Preliminary Budget. Town Law §109 sets
//  November 20 as the deadline to adopt; if the Board does not, the
//  Preliminary takes effect. The wording below switches on that date, so the
//  Home card and the 2027 proposal screen do not keep saying "Tentative" or
//  "comes later" after the Town has moved on. The web page it opens shows the
//  current stage from the Town's own documents.
//

import Foundation

enum Budget2027Status {
    /// The official 2027 budget page on Riverhead Budget Live.
    static let url = URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/tentative-2027/")!

    /// November 20, 2026, the last day to adopt under Town Law §109.
    static let adoptionDeadline: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 11; c.day = 20; c.hour = 23; c.minute = 59
        return Calendar(identifier: .gregorian).date(from: c) ?? .distantFuture
    }()

    static func isBeforeAdoptionDeadline(_ now: Date = .now) -> Bool {
        now <= adoptionDeadline
    }

    static func title(_ now: Date = .now) -> String {
        isBeforeAdoptionDeadline(now) ? "Read the 2027 Preliminary Budget" : "Read the 2027 budget"
    }

    static func summary(_ now: Date = .now) -> String {
        isBeforeAdoptionDeadline(now)
            ? "The Town's Preliminary is out. It is still a proposal: the Board must adopt a budget by November 20, 2026, or the Preliminary takes effect."
            : "The Board's deadline to adopt the 2027 budget was November 20, 2026. See the budget and how it changed from the Tentative."
    }

    /// A short status line for a badge or a corner of a card.
    static func shortStatus(_ now: Date = .now) -> String {
        isBeforeAdoptionDeadline(now) ? "Preliminary out · adoption due Nov 20" : "Adoption deadline passed Nov 20"
    }

    /// Browser-tab-style title for the web view.
    static let pageTitle = "2027 Budget"
}
