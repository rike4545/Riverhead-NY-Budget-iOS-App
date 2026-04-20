//
//  ToolRowTrailing.swift
//  Riverhead NY Budget App
//
//  Trailing badges/tokens for tool rows (money, pills, counts).
//  Swift 6 • iOS 17+
//

import SwiftUI

public enum ToolRowTrailing: Hashable, Sendable {
    case none
    case chevron
    case text(String)
    case count(Int)

    case pill(text: String, systemImage: String? = nil)
    case moneyCompact(Double, currencyCode: String = "USD")

    case multi([ToolRowTrailing])
}

public struct ToolRowTrailingView: View {
    public let trailing: ToolRowTrailing

    // Supports `ToolRowTrailingView(trailing: .pill(...))`
    public init(trailing: ToolRowTrailing) {
        self.trailing = trailing
    }

    // Supports `ToolRowTrailingView(.pill(...))`
    public init(_ trailing: ToolRowTrailing) {
        self.trailing = trailing
    }

    public var body: some View {
        switch trailing {
        case .none:
            EmptyView()

        case .chevron:
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)

        case .text(let s):
            pill(text: s, systemImage: nil)

        case .count(let n):
            pill(text: "\(n)", systemImage: "number")
                .accessibilityLabel("\(n) items")

        case .pill(let text, let systemImage):
            pill(text: text, systemImage: systemImage)

        case .moneyCompact(let amount, let currencyCode):
            pill(text: Self.compactCurrency(amount, code: currencyCode),
                 systemImage: "dollarsign.circle")

        case .multi(let list):
            HStack(spacing: 8) {
                ForEach(Array(list.enumerated()), id: \.offset) { _, item in
                    ToolRowTrailingView(trailing: item)
                }
            }
        }
    }

    private func pill(text: String, systemImage: String?) -> some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
            }
            Text(text)
                .font(.caption.weight(.semibold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.thinMaterial)
        .overlay(
            Capsule()
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
        )
        .clipShape(Capsule())
        .foregroundStyle(.secondary)
    }

    // MARK: - Formatting helpers

    /// Example: $29.0M, $104.4K
    public static func compactCurrency(_ amount: Double, code: String = "USD") -> String {
        let sign = amount < 0 ? "-" : ""
        let value = abs(amount)

        func format(_ v: Double, suffix: String) -> String {
            let s = String(format: "%.1f", v)
            return "\(s)\(suffix)"
        }

        let compact: String
        if value >= 1_000_000_000 {
            compact = format(value / 1_000_000_000, suffix: "B")
        } else if value >= 1_000_000 {
            compact = format(value / 1_000_000, suffix: "M")
        } else if value >= 1_000 {
            compact = format(value / 1_000, suffix: "K")
        } else {
            compact = String(format: "%.0f", value)
        }

        return "\(sign)\(currencySymbol(for: code))\(compact)"
    }

    private static func currencySymbol(for code: String) -> String {
        switch code.uppercased() {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        default: return "$"
        }
    }
}
