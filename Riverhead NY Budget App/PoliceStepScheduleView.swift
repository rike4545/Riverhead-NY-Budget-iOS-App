//
//  PoliceStepScheduleView.swift
//  Riverhead NY Budget App
//
//  How PBA step increases actually work. Two things move police pay and they
//  are easy to confuse: the across-the-board % raise that lifts the whole
//  schedule each year, and the step an individual officer climbs as they gain
//  service. The step is usually the larger of the two.
//
//  Mirrors the web edition's PoliceStepSchedule component.
//
//  Swift 6 · iOS 17+
//

import SwiftUI

@MainActor
struct PoliceStepScheduleView: View {

    @State private var selectedYear: Int = 2026

    var body: some View {
        List {
            ledeSection
            proposedContractsSection
            yearPickerSection
            officerScheduleSection
            legacyTierSection
            detectiveSection
            realRaisesSection
            academyRuleSection
            sourceSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Police Pay Steps")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Lede

    private var ledeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("Two things move police pay")
                    .font(.headline)
                Text("The contract raises the whole salary schedule by a set percentage each year. Separately, an individual officer climbs a step as they gain service. For an officer still on the ladder, the step is usually much larger than the across-the-board raise — which is why a department's payroll can grow faster than its contract percentage suggests.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Proposed 2027-2030 contracts

    private var proposedContractsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text(PoliceContracts2027.statusLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RiverheadTheme.brandCoral)
                Text("Items IX.26 and IX.27 on the Town Board's \(PoliceContracts2027.meetingDate) agenda ask it to approve stipulations with the PBA and the SOA. The agenda packet attaches their salary and night-differential schedules, not the stipulations themselves. Every step rises 3.75% a year, and 2027 salaries add $500 for the body-camera agreement.")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)

            ForEach(PoliceContracts2027.pbaOfficers + PoliceContracts2027.pbaDetectives + PoliceContracts2027.soaRanks) { row in
                contractRow(row)
            }

            DisclosureGroup("Night differential (yearly amounts)") {
                ForEach(PoliceContracts2027.nightDifferential) { row in
                    contractRow(row)
                }
            }
            .font(.footnote)

            Text("What it might cost: on the Police Officer ladder alone, the higher 2027 rates come to about \(PoliceContracts2027.ladderIncrease2027, format: .currency(code: "USD").precision(.fractionLength(0))) for the \(PoliceContracts2027.ladderOfficers) officers the website counts, on top of step raises owed either way. That is the website's estimate, not a Town figure, and it leaves out detectives, superior officers, night differential, overtime and pensions.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("A likely concern: both Fiscal Impact Statements answer \u{201C}\(PoliceContracts2027.fiscalImpactAnswer)\u{201D} and leave the cost sections blank.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Link("Open the November 17 agenda packet", destination: PoliceContracts2027.packetURL)
                .font(.footnote.weight(.semibold))
        } header: {
            Label("Proposed contracts, 2027 to 2030", systemImage: "doc.badge.clock")
        } footer: {
            Text("2026 → 2030. Pages 204–205 and 208–209 of the packet.")
        }
    }

    private func contractRow(_ row: PoliceContracts2027.Row) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(row.title)
                .font(.footnote.weight(.semibold))
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(row.rates[0], format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
                Text(row.rates[4], format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RiverheadTheme.brandNavy)
                    .monospacedDigit()
                Spacer(minLength: 6)
                Text("+\(row.fourYearChange * 100, specifier: "%.1f")%")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(RiverheadTheme.brandCoral)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
        .padding(.vertical, 1)
    }

    // MARK: - Year picker

    private var yearPickerSection: some View {
        Section {
            Picker("Contract year", selection: $selectedYear) {
                ForEach(PBAStepSchedule.years, id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Contract year")
            .accessibilityHint("Choose which year of the 2023 to 2026 PBA contract to show.")
        } footer: {
            Text("These are the 2023–2026 contract's rates. The contract expires 12/31/2026; the proposed 2027–2030 rates are above.")
        }
    }

    // MARK: - Officer ladder

    private var officerScheduleSection: some View {
        Section {
            let rows = PBAStepSchedule.officerScheduleHiredOnOrAfter20121203
            let top = rows.map { $0.value(for: selectedYear) }.max() ?? 1

            ForEach(rows) { row in
                let value = row.value(for: selectedYear)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.step)
                            .font(.footnote.weight(row.step.contains("top step") ? .bold : .regular))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        Text(value, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.brandNavy)
                            .monospacedDigit()
                    }
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(RiverheadTheme.Surface.card)
                            .frame(height: 6)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(RiverheadTheme.brandSky)
                                    .frame(width: geo.size.width * (value / top), height: 6)
                            }
                    }
                    .frame(height: 6)
                }
                .padding(.vertical, 2)
            }
        } header: {
            Label("Officers hired on or after 12/3/2012", systemImage: "stairs")
        } footer: {
            Text("Seven steps, Academy through 6th Year Officer, to reach top pay.")
        }
    }

    // MARK: - Legacy tier

    private var legacyTierSection: some View {
        Section {
            let legacy = PBAStepSchedule.officerTopStepHiredBefore20121203
            HStack(alignment: .firstTextBaseline) {
                Text(legacy.step)
                    .font(.footnote.weight(.bold))
                Spacer(minLength: 8)
                Text(legacy.value(for: selectedYear), format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.brandNavy)
                    .monospacedDigit()
            }
            Text("Officers hired before 12/3/2012 reach the same top dollar figure a full year sooner — their schedule has no separate 6th-year step. The rest of that legacy ladder isn't reproduced in the contract text, because no one hired before 12/3/2012 is still climbing it 13+ years later; every such officer is already at or near the top.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        } header: {
            Label("Officers hired before 12/3/2012", systemImage: "clock.arrow.circlepath")
        }
    }

    // MARK: - Detectives

    private var detectiveSection: some View {
        Section {
            ForEach(PBAStepSchedule.detectiveSchedule) { row in
                HStack(alignment: .firstTextBaseline) {
                    Text(row.step)
                        .font(.footnote)
                    Spacer(minLength: 8)
                    Text(row.value(for: selectedYear), format: .currency(code: "USD").precision(.fractionLength(0)))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RiverheadTheme.brandNavy)
                        .monospacedDigit()
                }
                .padding(.vertical, 1)
            }
        } header: {
            Label("Detective grades", systemImage: "shield.lefthalf.filled")
        } footer: {
            Text("Detective grade pay applies once promoted, regardless of hire date.")
        }
    }

    // MARK: - What the steps actually paid

    private var realRaisesSection: some View {
        Section {
            Text("What the ladder actually paid, 2025 → 2026. Each row is a group of Police Officers whose authorized salary moved by identical dollar amounts — the step increase and the across-the-board raise arriving together.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(PBAStepSchedule.realRaiseExamples) { ex in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(ex.fromStep) → \(ex.toStep)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.brandNavy)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        Text("\(ex.officerCount)")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(.secondary)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(ex.actual2025, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(ex.actual2026, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(RiverheadTheme.brandNavy)
                            .monospacedDigit()
                        Spacer(minLength: 6)
                        Text("+\(ex.raise, format: .currency(code: "USD").precision(.fractionLength(0)))")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(RiverheadTheme.brandCoral)
                            .monospacedDigit()
                    }
                }
                .padding(.vertical, 3)
            }

            Text("Every group's actual 2026 pay equals the contract's next-step 2026 rate plus a flat $2,550 that isn't itemized in Article XXXVI's base table — likely a holiday-pay or similar stipend the Board's authorized listing folds into “annual salary.” Not confirmed against contract text beyond Article XXXVI and Appendix B.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        } header: {
            Label("What the steps actually paid", systemImage: "arrow.up.right")
        } footer: {
            Text("The trailing number on each row is how many officers moved on that pair.")
        }
    }

    // MARK: - Academy rule

    private var academyRuleSection: some View {
        Section {
            Text(PBAStepSchedule.academyRuleExample)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        } header: {
            Label("How the Academy step transitions", systemImage: "graduationcap")
        }
    }

    // MARK: - Sources

    private var sourceSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 3) {
                Text(PBAStepSchedule.sourceTitle)
                    .font(.caption.weight(.semibold))
                Text(PBAStepSchedule.sourceNote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(PBAStepSchedule.realRaiseSourceTitle)
                    .font(.caption.weight(.semibold))
                Text(PBAStepSchedule.realRaiseSourceNote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 2)
        } header: {
            Label("Sources", systemImage: "doc.text")
        }
    }
}

#Preview {
    NavigationStack {
        PoliceStepScheduleView()
    }
}
