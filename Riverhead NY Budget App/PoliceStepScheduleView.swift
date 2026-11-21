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
    @State private var changeYear: Int = 2027

    var body: some View {
        List {
            ledeSection
            proposedContractsSection
            stepChangesSection
            k9Section
            longevitySection
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

    // MARK: - The 2027-2030 contracts

    private var proposedContractsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(PoliceContracts2027.statusLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(RiverheadTheme.brandCoral)
                Text("On \(PoliceContracts2027.meetingDate) the Town Board \(PoliceContracts2027.adopted == true ? "approved" : "is asked to approve") new contracts with the two police unions: officers and detectives (PBA), and sergeants and lieutenants (SOA). The Town has published the pay tables, but not the rest of the contracts.")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)

            plainPoint("Pay goes up by the same share every year for four years: 3.75%, a little under 4 cents on every dollar.")
            plainPoint("In 2027 everyone also gets $500 more for agreeing to wear body cameras, the last such increase.")
            plainPoint("A top-step police officer earns \(Self.money(top.rates[0])) this year. That \(PoliceContracts2027.adopted == true ? "becomes" : "would become") \(Self.money(top.rates[1])) next year and \(Self.money(top.rates[4])) in 2030: \(Self.money(top.rates[4] - top.rates[0])) more a year.")
            plainPoint("What it might cost: roughly \(Self.money((PoliceContracts2027.ladderIncrease2027 / 1000).rounded() * 1000)) more in 2027 for the \(PoliceContracts2027.ladderOfficers) rank-and-file officers the website counts, on top of the step raises the Town owes anyway. That is the website's estimate, not a Town figure, and it leaves out detectives, sergeants, lieutenants, night pay, overtime and pensions.")

            VStack(alignment: .leading, spacing: 6) {
                Text("Compared with the Town's civilian workers")
                    .font(.footnote.weight(.bold))
                Text("Most non-police employees are in the CSEA union. Their 2026–2029 contract was approved on December 16, 2025; it isn't new. For every $100 of pay today, the police \(PoliceContracts2027.adopted == true ? "contracts pay" : "proposal would pay") about \(Self.money(PoliceContracts2027.policePer100(by: 2029))) in 2029 and \(Self.money(PoliceContracts2027.policePer100(by: 2030))) in 2030. The CSEA contract pays about \(Self.money(PoliceContracts2027.cseaPer100(by: 2029))) in 2029, plus flat dollar raises, and then ends.")
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
                Text("For example, the middle CSEA salary on the 2026 list, \(Self.money(PoliceContracts2027.cseaTypical2026)), would reach about \(Self.money(PoliceContracts2027.cseaSalary(from: PoliceContracts2027.cseaTypical2026, by: 2029))) in 2029.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach([2027, 2028, 2029, 2030], id: \.self) { year in
                    HStack {
                        Text(String(year)).font(.caption.weight(.semibold))
                        Spacer()
                        Text("Police: \(year == 2027 ? "3.75% and $500" : "3.75%")")
                            .font(.caption)
                        Text("CSEA: \(cseaLabel(year))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.vertical, 2)

            plainPoint("Something to ask about: the form that says whether a resolution costs money answers \u{201C}No\u{201D} on both, with the cost lines blank. A four-year raise does cost money.")

            DisclosureGroup("See every pay step and the night pay") {
                ForEach(PoliceContracts2027.pbaOfficers + PoliceContracts2027.pbaDetectives + PoliceContracts2027.soaRanks + PoliceContracts2027.nightDifferential) { row in
                    contractRow(row)
                }
            }
            .font(.footnote)

            Link("Open the November 17 agenda packet", destination: PoliceContracts2027.packetURL)
                .font(.footnote.weight(.semibold))
        } header: {
            Label(PoliceContracts2027.adopted == true ? "New contracts, 2027 to 2030" : "Proposed contracts, 2027 to 2030", systemImage: "doc.badge.clock")
        } footer: {
            Text("Pay tables from pages 204–205 and 208–209 of the agenda packet.")
        }
    }

    private var top: PoliceContracts2027.Row { PoliceContracts2027.pbaOfficers[6] }

    // MARK: - Step salaries, year by year

    private var stepChangesSection: some View {
        Section {
            Picker("Year", selection: $changeYear) {
                ForEach([2027, 2028, 2029, 2030], id: \.self) { Text(String($0)).tag($0) }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Contract year")

            Text(changeYear == 2027
                 ? "Each step rises 3.75% from 2026, plus the $500 body-camera amount."
                 : "Each step rises 3.75% from \(String(changeYear - 1)).")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(PoliceContracts2027.pbaOfficers + PoliceContracts2027.pbaDetectives + PoliceContracts2027.soaRanks) { row in
                if let c = PoliceContracts2027.yearlyChanges(row).first(where: { $0.year == changeYear }) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.title)
                            .font(.footnote.weight(.semibold))
                        Spacer(minLength: 6)
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(c.rate, format: .currency(code: "USD").precision(.fractionLength(2)))
                                .font(.footnote.weight(.bold))
                                .monospacedDigit()
                            Text("+\(c.change.formatted(.currency(code: "USD").precision(.fractionLength(2)))) (\((c.pct * 100).formatted(.number.precision(.fractionLength(2))))%)")
                                .font(.caption2)
                                .foregroundStyle(RiverheadTheme.brandCoral)
                                .monospacedDigit()
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        } header: {
            Label("Step salaries, year by year", systemImage: "chart.line.uptrend.xyaxis")
        } footer: {
            Text("Appendix B of each stipulation, agenda packet pages 205 (PBA) and 209 (SOA). Approved November 17, 2026, Resolutions 2026-1020 and 2026-1021.")
        }
    }

    // MARK: - K-9

    private var k9Section: some View {
        Section {
            Text("K-9 officers receive a yearly K-9 amount on top of salary. It rises 3.75% a year with the night differentials.")
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Array(PoliceContracts2027.years.enumerated()), id: \.offset) { i, year in
                HStack {
                    Text(String(year)).font(.footnote.weight(.semibold))
                    Spacer()
                    Text(PoliceContracts2027.k9.rates[i], format: .currency(code: "USD").precision(.fractionLength(2)))
                        .font(.footnote.weight(i == 0 ? .regular : .bold))
                        .monospacedDigit()
                    if i > 0 {
                        Text("+\((PoliceContracts2027.k9.rates[i] - PoliceContracts2027.k9.rates[i - 1]).formatted(.currency(code: "USD").precision(.fractionLength(2))))")
                            .font(.caption2)
                            .foregroundStyle(RiverheadTheme.brandCoral)
                            .monospacedDigit()
                    }
                }
                .accessibilityElement(children: .combine)
            }
            let officers = PoliceContracts2027.k9Officers
            if !officers.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("In the K-9 unit on the 2025 payroll")
                        .font(.footnote.weight(.bold))
                    ForEach(officers, id: \.n) { o in
                        Text("\(o.n), \(o.t ?? "")")
                            .font(.footnote)
                    }
                    Text("At \(PoliceContracts2027.k9.rates[1].formatted(.currency(code: "USD").precision(.fractionLength(0)))) each in 2027, the K-9 amount for \(officers.count) officer\(officers.count == 1 ? "" : "s") comes to \((PoliceContracts2027.k9.rates[1] * Double(officers.count)).formatted(.currency(code: "USD").precision(.fractionLength(0)))), if the unit keeps the same handlers.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)
            }
        } header: {
            Label("K-9 pay", systemImage: "pawprint.fill")
        } footer: {
            Text("PBA Appendix A, agenda packet page 204. The unit's handlers are those the Town's 2025 payroll export lists in the K-9 department.")
        }
    }

    // MARK: - Longevity at 25 years

    private var longevitySection: some View {
        let people = PoliceContracts2027.longevityCandidates
        return Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("From January 1, 2028, both contracts add longevity pay of 8% of base pay after 25 years of consecutive service.")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                Text("This term is not in the agenda packet, which printed only the pay tables. It was reported by RiverheadLOCAL: \u{201C}\(PoliceContracts2027.longevityQuote)\u{201D}")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Link("Read the RiverheadLOCAL report", destination: PoliceContracts2027.longevityURL)
                    .font(.caption.weight(.semibold))
            }
            .padding(.vertical, 2)

            ForEach([2028, 2029, 2030], id: \.self) { year in
                let total = PoliceContracts2027.longevityTotal(in: year)
                let count = people.filter { $0.qualifies(in: year) }.count
                let priced = people.filter { $0.amount(in: year) != nil }.count
                HStack {
                    Text("\(String(year)): \(count) eligible\(priced < count ? ", \(priced) priced" : "")")
                        .font(.footnote.weight(.semibold))
                    Spacer()
                    Text(rangeText(total))
                        .font(.footnote.weight(.bold))
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
            }

            DisclosureGroup("Who would receive it, and how much") {
                ForEach(people) { person in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(person.name)
                            .font(.footnote.weight(.semibold))
                        Text("\(person.title.replacingOccurrences(of: "  ", with: " ")) · \(person.union) · hired \(person.hireDate.formatted(date: .abbreviated, time: .omitted)) · 25 years on \(person.reaches25.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if person.baseRows.isEmpty {
                            Text("This title is not on either salary schedule, so no amount is shown.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } else {
                            HStack(spacing: 10) {
                                ForEach([2028, 2029, 2030], id: \.self) { year in
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(String(year)).font(.caption2).foregroundStyle(.secondary)
                                        Text(person.amount(in: year).map(rangeText) ?? (person.reachesDuring(year) ? "from \(person.reaches25.formatted(.dateTime.month(.abbreviated).day()))" : "—"))
                                            .font(.caption.weight(.semibold))
                                            .monospacedDigit()
                                    }
                                }
                            }
                        }
                        if person.longevityPaid2025 > 0 {
                            Text("Longevity paid in 2025 under the current contract: \(Self.money(person.longevityPaid2025)).")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .padding(.vertical, 2)
                }
            }
            .font(.footnote)
        } header: {
            Label("Longevity pay at 25 years", systemImage: "clock.badge.checkmark")
        } footer: {
            Text("This app's estimate, not a Town figure. It takes everyone on the 2025 police payroll whose hire date reaches 25 years by 2030, and 8% of their rank's scheduled salary, for those with 25 years by January 1 of each year. Officers with 25 years are at the top step. The payroll doesn't give a detective's grade, so detectives show a range from grade III to grade I. The list is the 2025 payroll: seven PBA members retired under the 2026 incentive and are not identified. The hire date stands in for consecutive service, \u{201C}total base pay\u{201D} may include more than the schedule salary, and the contracts' own longevity rules for part years and for the current longevity pay are not public.")
        }
    }

    private func rangeText(_ r: ClosedRange<Double>) -> String {
        r.lowerBound == r.upperBound
            ? Self.money(r.lowerBound)
            : "\(Self.money(r.lowerBound))–\(Self.money(r.upperBound))"
    }

    private static func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private func cseaLabel(_ year: Int) -> String {
        guard let t = PoliceContracts2027.cseaTerms.first(where: { $0.year == year }) else { return "contract ends" }
        let pct = (t.pct * 100).formatted(.number.precision(.fractionLength(0...2)))
        return t.flat > 0 ? "\(pct)% and \(Self.money(t.flat))" : "\(pct)%"
    }

    private func plainPoint(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 1)
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
                Text("+\(Self.money(row.rates[4] - row.rates[0]))")
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
            Text("These are the 2023–2026 contract's rates. The contract expires 12/31/2026; the \(PoliceContracts2027.adopted == true ? "new" : "proposed") 2027–2030 rates are above.")
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
