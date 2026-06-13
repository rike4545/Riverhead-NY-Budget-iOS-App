//
//  FundBalanceShiftView.swift
//  Riverhead NY Budget App
//  Swift 6 / iOS 17+
//
//  Visualizes policy thresholds and lets users run what-ifs.
//  Self-contained: no dependency on RBBudgetStore.
//  Safe formatters (NumberFormatter), no NavigationStack to avoid init ambiguity.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import Foundation

public struct FundBalanceShiftView: View {
    // Inputs (you can seed these from real data later)
    @State private var appropriations: Double = 69_113_159
    @State private var estimatedFundBalance: Double = 28_403_924
    @State private var minPercent: Double = 0.15   // 15%
    @State private var policyNotes: String = "Minimum unassigned fund balance of 15% of next-year appropriations."
    @State private var replenishYears: Int = 3

    // Formatters
    private let nfCurrency: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.maximumFractionDigits = 0
        return nf
    }()

    private let nfPercent: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .percent
        nf.maximumFractionDigits = 1
        return nf
    }()

    // Computations
    private var minimumRequired: Double { max(0, appropriations * minPercent) }
    private var surplus: Double { estimatedFundBalance - minimumRequired }
    private var ratio: Double {
        guard minimumRequired > 0 else { return 1 }
        return max(estimatedFundBalance / minimumRequired, 0)
    }
    private var progressRatio: Double {
        min(ratio, 1)
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                shareRow
                thresholdsCard
                whatIfCard
                policyCard
            }
            .padding()
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Fund Balance")
                .font(.title.bold())
            Text("Policy minimum vs. estimated unassigned fund balance")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var shareRow: some View {
        HStack(spacing: 12) {
            ShareLink(item: shareText) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.footnote.weight(.medium))
            }

            Button {
                #if canImport(UIKit)
                UIPasteboard.general.string = shareText
                #endif
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.footnote.weight(.medium))
            }

            Spacer()
        }
        .tint(.primary)
    }

    private var shareText: String {
        let a = nfCurrency.string(from: appropriations as NSNumber) ?? "—"
        let e = nfCurrency.string(from: estimatedFundBalance as NSNumber) ?? "—"
        let p = nfPercent.string(from: minPercent as NSNumber) ?? "—"
        let m = nfCurrency.string(from: minimumRequired as NSNumber) ?? "—"
        let s = nfCurrency.string(from: abs(surplus) as NSNumber) ?? "—"
        let label = (surplus >= 0) ? "Cushion above Minimum" : "Shortfall to Minimum"

        return "RIVERHEAD • FUND BALANCE WHAT-IF (UNOFFICIAL)\n\nAppropriations: \(a)\nEstimated Fund Balance: \(e)\nPolicy Minimum: \(p) → \(m)\n\(label): \(s)\n\nNotes: \(policyNotes)\nReplenish within: \(replenishYears) year(s)\n\nAlways verify with the Town’s adopted budget and audited financials."
    }

    private var thresholdsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                LabeledContent("Appropriations") {
                    Text(nfCurrency.string(from: appropriations as NSNumber) ?? "—")
                        .monospacedDigit()
                }
                LabeledContent("Estimated Fund Balance (12/31)") {
                    Text(nfCurrency.string(from: estimatedFundBalance as NSNumber) ?? "—")
                        .monospacedDigit()
                }
                LabeledContent("Policy Minimum (\(nfPercent.string(from: minPercent as NSNumber) ?? "—"))") {
                    Text(nfCurrency.string(from: minimumRequired as NSNumber) ?? "—")
                        .monospacedDigit()
                }

                Divider()

                LabeledContent(surplus >= 0 ? "Cushion above Minimum" : "Shortfall to Minimum") {
                    Text(nfCurrency.string(from: abs(surplus) as NSNumber) ?? "—")
                        .monospacedDigit()
                        .foregroundStyle(surplus >= 0 ? .green : .red)
                }

                ProgressView(value: progressRatio)
                    .tint(surplus >= 0 ? .green : .red)
                    .accessibilityLabel("Estimated balance as a fraction of minimum")
            }
        }
    }

    private var whatIfCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("What-if: Adjust Inputs")
                    .font(.headline)

                Stepper(value: $appropriations, in: 0...1_000_000_000, step: 50_000) {
                    HStack {
                        Text("Appropriations")
                        Spacer()
                        Text(nfCurrency.string(from: appropriations as NSNumber) ?? "—")
                            .monospacedDigit()
                    }
                }

                Stepper(value: $estimatedFundBalance, in: 0...1_000_000_000, step: 50_000) {
                    HStack {
                        Text("Est. Fund Balance")
                        Spacer()
                        Text(nfCurrency.string(from: estimatedFundBalance as NSNumber) ?? "—")
                            .monospacedDigit()
                    }
                }

                // Percent stepper with 0.5% steps
                Stepper(value: $minPercent, in: 0...1, step: 0.005) {
                    HStack {
                        Text("Policy Minimum %")
                        Spacer()
                        Text(nfPercent.string(from: minPercent as NSNumber) ?? "—")
                            .monospacedDigit()
                    }
                }
            }
        }
    }

    private var policyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Policy Notes")
                    .font(.headline)

                if !policyNotes.isEmpty {
                    Text(policyNotes)
                }

                Text("Recommended replenishment timeline: \(replenishYears) year\(replenishYears == 1 ? "" : "s").")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Simple Card styling
fileprivate struct Card<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                .thinMaterial,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.primary.opacity(scheme == .dark ? 0.10 : 0.06))
            )
    }
}

// MARK: - Preview

#Preview {
    FundBalanceShiftView()
}
