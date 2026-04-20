//
//  RiverheadURLs.swift
//  Riverhead NY Helper
//
//  Central place for all URLs used by the app.
//  This app is an unofficial, community-made helper that links to
//  publicly available pages on townofriverheadny.gov.
//

import Foundation

/// Namespace for well-known Town of Riverhead website URLs.
///
/// All URLs here are public pages on townofriverheadny.gov or
/// the town's official social media accounts.
enum RiverheadURLs {

    // MARK: - Base

    /// Root of the official town website.
    static let base = URL.verified("https://www.townofriverheadny.gov")

    /// Convenience alias for the homepage.
    static let home = base

    // MARK: - Main Navigation Sections

    /// “How Do I…” landing page (Apply, Find, Contact, Submit, etc.)
    static let howDoI = URL.verified("https://www.townofriverheadny.gov/9/How-Do-I")

    /// “Services” overview page.
    static let services = URL.verified("https://www.townofriverheadny.gov/101/Services")

    /// Departments directory (Accounting, Assessor, Building, etc.)
    static let departments = URL.verified("https://www.townofriverheadny.gov/31/Departments")

    /// “Government” section (Town Board, Supervisor, other elected offices).
    static let government = URL.verified("https://www.townofriverheadny.gov/27/Government")

    // MARK: - News & Events

    /// CivicAlerts “News Flash” page with town news items.
    static let newsFlash = URL.verified("https://www.townofriverheadny.gov/CivicAlerts.aspx")

    /// Town-wide calendar (meetings, hearings, community events).
    static let calendar = URL.verified("https://www.townofriverheadny.gov/Calendar.aspx")

    // MARK: - Online Services / Popular Tasks

    /// Online payments & services hub (tax, water, tickets, rec, etc.).
    static let onlinePayments = URL.verified("https://www.townofriverheadny.gov/164/Online-Payments-Services")

    /// Online Code Enforcement Violation Complaint form.
    ///
    /// Used by the “Report” quick action in the app.
    static let reportConcern = URL.verified(
        "https://www.townofriverheadny.gov/FormCenter/Code-Enforcement-10/Online-Code-Enforcement-Violation-Compla-53"
    )

    /// Quick Links page (Town Code, maps, bid requests, etc.).
    static let quickLinks = URL.verified("https://www.townofriverheadny.gov/159/Quick-Links")

    /// Channel 22 live streams & video archives for meetings and programming.
    static let channel22 = URL.verified(
        "https://www.townofriverheadny.gov/462/Channel-22---Live-Streams-and-Video-Arch"
    )

    // MARK: - Contact / Map

    /// General “Contact Us” page on the town website.
    static let contactUs = URL.verified("https://www.townofriverheadny.gov/contactus")

    // MARK: - Social Media (public accounts)

    /// Official Town of Riverhead YouTube channel.
    static let youtube = URL.verified("https://www.youtube.com/@TownOfRiverhead")

    /// Official Town of Riverhead Instagram account.
    static let instagram = URL.verified("https://www.instagram.com/townofriverhead")

    /// Official Town of Riverhead Facebook page.
    static let facebook = URL.verified("https://www.facebook.com/riverheadtown")
}
