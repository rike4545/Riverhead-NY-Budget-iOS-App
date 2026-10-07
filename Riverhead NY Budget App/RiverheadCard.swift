//
//  RiverheadCard.swift
//  Riverhead NY Budget App
//
//  One card surface for the whole app.
//
//  RiverheadTheme already carried the palette, the adaptive surfaces and
//  cardShadow(_:elevated:), and the older screens (YearlyEarnings,
//  FundBalanceTrendView, PeerReserveBenchmarkView and six more) already built a
//  good card on top of it: material when transparency is allowed, an opaque
//  surface when it is not, and border and shadow tuned per colour scheme.
//
//  The newer parity screens each grew their own copy instead, and the copies
//  drifted into two families — padding 14 against 16, .regularMaterial against
//  .thinMaterial, RiverheadTheme.border at 0.35 against the system separator at
//  0.22 — so screens one tap apart did not match. None of the copies honoured
//  Reduce Transparency, which the older screens had handled all along.
//
//  This generalises the older pattern so there is one implementation to fix.
//

import SwiftUI

extension RiverheadTheme {

    /// Corner radii, as a deliberate scale. The app had accumulated seventeen
    /// distinct values; these four cover what it actually needs, and `card`
    /// keeps the 16 that was already the most common by a wide margin.
    enum Radius {
        /// Badges, pills and inline chips.
        static let chip: CGFloat = 8
        /// Buttons, fields and inset rows.
        static let control: CGFloat = 12
        /// The standard card.
        static let card: CGFloat = 16
        /// Sheets, hero panels and anything full-bleed.
        static let hero: CGFloat = 22
    }

    enum CardPadding {
        static let standard: CGFloat = 16
        static let compact: CGFloat = 12
    }
}

/// The app's card surface: material where the reader allows it, an opaque
/// surface where they do not, with the border and shadow weighted for the
/// current colour scheme.
struct RiverheadCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    // The older screens honour this and the newer ones did not. Reduce
    // Transparency is a readability setting, not a cosmetic one: over the app's
    // background gradient, translucent cards are exactly what it turns off.
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let padding: CGFloat
    let radius: CGFloat
    /// A 4pt status stripe down the leading edge, as the officials roster uses
    /// to carry pension status without relying on colour alone for meaning.
    let accentEdge: Color?
    let elevated: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        return content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: shape)
            .overlay(alignment: .leading) { stripe }
            .overlay(shape.strokeBorder(RiverheadTheme.softBorder, lineWidth: 0.8))
            .shadow(
                color: RiverheadTheme.cardShadow(scheme, elevated: elevated),
                radius: elevated ? 10 : 8,
                x: 0,
                y: elevated ? 4 : 3
            )
    }

    private var fill: AnyShapeStyle {
        if reduceTransparency {
            return AnyShapeStyle(elevated ? RiverheadTheme.Surface.elevated : RiverheadTheme.Surface.card)
        }
        // Dark mode gets the thinner material: the regular one over an already
        // dark gradient reads as a flat grey slab rather than a raised card.
        return AnyShapeStyle(scheme == .dark ? .ultraThinMaterial : .regularMaterial)
    }

    @ViewBuilder
    private var stripe: some View {
        if let accentEdge {
            Rectangle()
                .fill(accentEdge)
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                .padding(.vertical, 6)
        }
    }
}

extension View {
    /// The app's standard card. Prefer this over a per-file copy.
    func riverheadCard(
        padding: CGFloat = RiverheadTheme.CardPadding.standard,
        radius: CGFloat = RiverheadTheme.Radius.card,
        accentEdge: Color? = nil,
        elevated: Bool = false
    ) -> some View {
        modifier(
            RiverheadCardStyle(
                padding: padding,
                radius: radius,
                accentEdge: accentEdge,
                elevated: elevated
            )
        )
    }
}
