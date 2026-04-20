//
//  FundBalancePoliciesView_FIXED.swift
//  Riverhead NY Budget App
//
//  Fixes:
//  - Removes fragile nested string-interpolation with escaped quotes (unterminated string bug)
//  - Provides Share + Copy output using safe string assembly
//  - Keeps Riverhead-themed card layout and uses RBFundBalancePolicy helpers
//
//  Swift 6 • iOS 17+
//

import SwiftUI
import Observation
import UIKit

@MainActor
struct FundBalancePoliciesView: View {
    @Environment(RBBudgetStore.self) private var store

    @State private var appropriationsBaseline: Double = 120_000_000

    @State private var gfPolicy: RBFundBalancePolicy = RiverheadFundBalancePolicyBook.general()
    @State private var otherPolicy: RBFundBalancePolicy = RiverheadFundBalancePolicyBook.otherOperating()

    @State private var showShareSheet = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                heroCard
                appropriationsCard
                policyCard(title: "General Fund", policy: $gfPolicy)
                policyCard(title: "Other Operating Funds", policy: $otherPolicy)
                actionsCard
            }
            .padding(16)
        }
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Policies")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share policy what-if")
            }
        }
        .onAppear {
            // If you have real appropriations totals in store later, wire them here.
            // Keep this safe: don't crash if store data isn't loaded.
            // Example: if store exposes a number, set it once.
        }
    }

    // MARK: - Cards

    private var heroCard: some View {
        card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Fund balance policies")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Text("Set policy targets for unassigned fund balance as a share of next-year appropriations. These are **unofficial what-ifs** meant to help interpret budgets and audits.")
                    .font(.subheadline)
                    .foregroundStyle(RiverheadTheme.textSecondary.opacity(0.9))
            }
        }
    }

    private var appropriationsCard: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text("What-if appropriations baseline")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)

                HStack {
                    Text("Next-year appropriations")
                        .foregroundStyle(RiverheadTheme.textSecondary)
                    Spacer()
                    Text(appropriationsBaseline, format: .currency(code: "USD"))
                        .monospacedDigit()
                        .foregroundStyle(RiverheadTheme.textPrimary)
                }

                Slider(value: $appropriationsBaseline, in: 0...400_000_000, step: 1_000_000)
                Text("Used to translate policy % targets into dollar thresholds.")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary.opacity(0.9))
            }
        }
    }

    private func policyCard(title: String, policy: Binding<RBFundBalancePolicy>) -> some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(RiverheadTheme.textPrimary)
                    Spacer()
                }

                percentRow(
                    label: "Minimum target",
                    value: Binding(
                        get: { policy.wrappedValue.minimumPercent * 100 },
                        set: { policy.wrappedValue.minimumPercent = max(0, $0 / 100) }
                    ),
                    hint: "Minimum unassigned fund balance as % of appropriations."
                )

                optionalUpperRow(policy: policy)

                Stepper(value: Binding(
                    get: { Double(policy.wrappedValue.replenishYears ?? 3) },
                    set: { policy.wrappedValue.replenishYears = Int($0) }
                ), in: 1...10, step: 1) {
                    HStack {
                        Text("Replenish window")
                            .foregroundStyle(RiverheadTheme.textSecondary)
                        Spacer()
                        Text("\(policy.wrappedValue.replenishYears ?? 3) years")
                            .foregroundStyle(RiverheadTheme.textPrimary)
                    }
                }

                let minReq = policy.wrappedValue.minimumRequired(appropriations: appropriationsBaseline)
                let upper = policy.wrappedValue.targetUpper(appropriations: appropriationsBaseline)

                Divider().opacity(0.5)

                HStack {
                    Text("Minimum (dollars)")
                        .foregroundStyle(RiverheadTheme.textSecondary)
                    Spacer()
                    Text(minReq, format: .currency(code: "USD"))
                        .monospacedDigit()
                        .foregroundStyle(RiverheadTheme.textPrimary)
                }

                if let upper {
                    HStack {
                        Text("Upper band (dollars)")
                            .foregroundStyle(RiverheadTheme.textSecondary)
                        Spacer()
                        Text(upper, format: .currency(code: "USD"))
                            .monospacedDigit()
                            .foregroundStyle(RiverheadTheme.textPrimary)
                    }
                }

                if !policy.wrappedValue.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(policy.wrappedValue.notes)
                        .font(.caption)
                        .foregroundStyle(RiverheadTheme.textSecondary.opacity(0.9))
                }
            }
        }
    }

    private func optionalUpperRow(policy: Binding<RBFundBalancePolicy>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Upper band (optional)")
                    .foregroundStyle(RiverheadTheme.textSecondary)
                Spacer()
                let upperPct = (policy.wrappedValue.targetUpperPercent ?? 0) * 100
                Text(policy.wrappedValue.targetUpperPercent == nil ? "None" : "\(Int(upperPct))%")
                    .foregroundStyle(RiverheadTheme.textPrimary)
            }

            Toggle(isOn: Binding(
                get: { policy.wrappedValue.targetUpperPercent != nil },
                set: { enabled in
                    if enabled {
                        policy.wrappedValue.targetUpperPercent = max(policy.wrappedValue.minimumPercent, 0.20)
                    } else {
                        policy.wrappedValue.targetUpperPercent = nil
                    }
                }
            )) {
                Text("Enable upper band")
                    .foregroundStyle(RiverheadTheme.textSecondary)
            }
            .toggleStyle(.switch)

            if policy.wrappedValue.targetUpperPercent != nil {
                let binding = Binding(
                    get: { (policy.wrappedValue.targetUpperPercent ?? 0) * 100 },
                    set: { policy.wrappedValue.targetUpperPercent = max(0, $0 / 100) }
                )
                percentRow(
                    label: "Upper band",
                    value: binding,
                    hint: "A soft ceiling for unusually high unassigned balances."
                )
            }
        }
    }

    private var actionsCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Export")
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)

                ShareLink(item: shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Button {
                    UIPasteboard.general.string = shareText
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                Text("Always confirm with the Town’s adopted resolutions and audited financial statements.")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary.opacity(0.9))
            }
        }
    }

    // MARK: - Share Text (SAFE)

    private var shareText: String {
        let base = appropriationsBaseline.formatted(.currency(code: "USD"))
        let gfBlock = policyShareBlock(title: "General Fund", policy: gfPolicy)
        let otherBlock = policyShareBlock(title: "Other Operating Funds", policy: otherPolicy)

        // Assemble with an array to avoid fragile nested interpolation/escaping.
        return [
            "RIVERHEAD • FUND BALANCE POLICY WHAT-IF (UNOFFICIAL)",
            "",
            "Appropriations baseline: \(base)",
            "",
            gfBlock,
            "",
            otherBlock,
            "",
            "Always confirm with the Town’s adopted resolutions and audited financial statements."
        ].joined(separator: "\n")
    }

    private func policyShareBlock(title: String, policy: RBFundBalancePolicy) -> String {
        let minPct = policy.minimumPercent.formatted(.percent.precision(.fractionLength(1)))
        let minDollars = policy.minimumRequired(appropriations: appropriationsBaseline).formatted(.currency(code: "USD"))
        let upperPct = policy.targetUpperPercent?.formatted(.percent.precision(.fractionLength(1))) ?? "—"
        let upperDollars = policy.targetUpper(appropriations: appropriationsBaseline).map { $0.formatted(.currency(code: "USD")) } ?? "—"
        let years = policy.replenishYears ?? 3

        return [
            "\(title)",
            "• Minimum: \(minPct)  (\(minDollars))",
            "• Upper: \(upperPct)  (\(upperDollars))",
            "• Replenish window: \(years) years"
        ].joined(separator: "\n")
    }

    // MARK: - UI Helpers

    private func percentRow(label: String, value: Binding<Double>, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                Spacer()
                Text((value.wrappedValue / 100).formatted(.percent.precision(.fractionLength(0))))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                    .monospacedDigit()
            }
            Slider(value: value, in: 0...40, step: 0.5)
            Text(hint)
                .font(.caption2)
                .foregroundStyle(RiverheadTheme.textSecondary.opacity(0.9))
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(RiverheadTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(RiverheadTheme.cardStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
    }
}
