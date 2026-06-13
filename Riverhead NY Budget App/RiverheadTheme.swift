//
//  RiverheadTheme.swift
//  Riverhead NY Budget App
//
//  Unified theme tuned to the official Town of Riverhead website.
//  Swift 6 • iOS 17+
//
//  IMPORTANT
//  - Many views in this project reference `RiverheadTheme.Surface.page` and `.card`.
//  - This file preserves legacy aliases (primaryBlue, gold, tint, border, slateText,
//    Color.page / .card, etc.) so existing views compile.
//

import SwiftUI

enum RiverheadTheme {

    // MARK: - Brand Palette (sampled from townofriverheadny.gov)

    /// Deep navy used in the logo & some header elements (#19537B).
    static let brandNavy: Color = Color(red: 0.098, green: 0.325, blue: 0.482)

    /// Medium header/nav blue (#4E7595).
    static let brandBlue: Color = Color(red: 0.306, green: 0.459, blue: 0.584)

    /// Shoreline / pie-chart blue accent (#4285A7).
    static let brandSky: Color = Color(red: 0.259, green: 0.522, blue: 0.655)

    /// Soft teal used in charts / accents (#8DBABE).
    static let brandTeal: Color = Color(red: 0.553, green: 0.729, blue: 0.745)

    /// Gold stripe from the logo (#BDAC34).
    static let brandGold: Color = Color(red: 0.741, green: 0.675, blue: 0.204)

    /// Warm sand used as a low-volume complement to the shoreline blues.
    static let brandSand: Color = Color(red: 0.812, green: 0.760, blue: 0.541)

    /// Fresh civic green used sparingly for positive signals and service cards.
    static let brandMint: Color = Color(red: 0.290, green: 0.595, blue: 0.520)

    /// Warm civic accent for alerts, deadlines, and calls to action.
    static let brandCoral: Color = Color(red: 0.775, green: 0.314, blue: 0.235)

    /// Light/dark adaptive page background.
    static let brandBackground: Color = Color(
        uiColor: UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                // Deep blue-gray tuned for readable dark-mode contrast.
                return UIColor(red: 0.043, green: 0.057, blue: 0.075, alpha: 1.0)
            }
            return UIColor(red: 0.914, green: 0.943, blue: 0.953, alpha: 1.0)
        }
    )

    /// Light/dark adaptive card background.
    static let brandCard: Color = Color(
        uiColor: UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor(red: 0.094, green: 0.118, blue: 0.153, alpha: 1.0)
            }
            return UIColor(red: 0.984, green: 0.992, blue: 0.988, alpha: 1.0)
        }
    )

    // MARK: - Core Tokens (used by the app)

    /// Primary Riverhead blue used across the app (deep navy).
    static let primaryBlue: Color = brandNavy

    /// Accent color for controls and highlights (header/nav blue).
    static let accent: Color = brandNavy

    /// Legacy alias used in older views (same as `accent`).
    static let tint: Color = accent

    /// Gold accent for callouts, highlights, and budget key figures.
    static let gold: Color = brandGold

    /// Legacy alias sometimes used in older code.
    static let accentGold: Color = gold

    // MARK: - Surfaces

    /// App-wide background color (behind everything).
    static let background: Color = brandBackground

    /// Default card / panel background (lists, tiles, panels).
    static let cardBackground: Color = brandCard

    /// Standard app surfaces.
    enum Surface {
        /// Page background (behind scrolling content)
        static var page: Color { RiverheadTheme.background }

        /// Card / tile background
        static var card: Color { RiverheadTheme.cardBackground }

        /// More pronounced panel surface for headers and important controls.
        static var elevated: Color {
            Color(
                uiColor: UIColor { trait in
                    trait.userInterfaceStyle == .dark
                    ? UIColor(red: 0.120, green: 0.153, blue: 0.194, alpha: 1.0)
                    : UIColor.white
                }
            )
        }

        /// Slightly different surface you can use for inset areas
        static var inset: Color { RiverheadTheme.background.opacity(0.985) }
    }

    /// If any older code expects a single surface color, use this.
    static var surface: Color { cardBackground }

    /// Subtle border / divider color for cards and panels.
    static let softBorder: Color = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.18)
            : UIColor.black.withAlphaComponent(0.08)
        }
    )

    /// Legacy alias used by some older views for border color.
    static let border: Color = softBorder

    /// Compatibility alias used by some Shift views.
    static let cardStroke: Color = softBorder

    /// Slightly muted background that can be used behind secondary sections.
    static let mutedBackground: Color = background.opacity(0.96)

    // MARK: - Text

    static let textPrimary: Color = Color.primary
    static let textSecondary: Color = Color.secondary

    /// Legacy alias used by some older views.
    static let slateText: Color = textSecondary

    // MARK: - Utility Gradients

    /// Gradient inspired by the site’s shoreline hero (sky blue into soft bg).
    static var headerGradient: LinearGradient {
        LinearGradient(
            colors: [
                brandNavy,
                brandSky.opacity(0.92),
                brandTeal.opacity(0.78),
                brandGold.opacity(0.62)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Subtle background gradient you can use under whole screens.
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                brandNavy.opacity(0.18),
                brandSky.opacity(0.25),
                brandBackground,
                brandTeal.opacity(0.18),
                brandGold.opacity(0.10),
                Color(uiColor: UIColor { trait in
                    trait.userInterfaceStyle == .dark
                    ? UIColor(red: 0.035, green: 0.047, blue: 0.067, alpha: 1.0)
                    : UIColor(red: 0.976, green: 0.982, blue: 0.969, alpha: 1.0)
                })
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static let townAccentPalette: [Color] = [
        brandNavy,
        brandBlue,
        brandSky,
        brandTeal,
        brandGold,
        brandMint
    ]

    static func townAccent(for key: String) -> Color {
        let scalarTotal = key.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return townAccentPalette[abs(scalarTotal) % townAccentPalette.count]
    }

    static func cardShadow(_ scheme: ColorScheme, elevated: Bool = false) -> Color {
        Color.black.opacity(scheme == .dark ? (elevated ? 0.42 : 0.28) : (elevated ? 0.14 : 0.08))
    }
}

// MARK: - Legacy Color helpers used by older views

extension Color {
    /// Static "page" background used in some budget views.
    static var page: Color { RiverheadTheme.background }

    /// Static "card" surface used in some budget views.
    static var card: Color { RiverheadTheme.cardBackground }

    /// Instance "page" alias so older code like `Color.white.page` still compiles.
    var page: Color { RiverheadTheme.background }

    /// Instance "card" alias used in some older views.
    var card: Color { RiverheadTheme.cardBackground }
}
