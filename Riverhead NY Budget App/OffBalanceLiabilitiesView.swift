import SwiftUI

@MainActor
struct OffBalanceLiabilitiesView: View {
    private enum ExposureLevel: String {
        case high = "High"
        case medium = "Medium"
        case watch = "Watch"

        var color: Color {
            switch self {
            case .high: return RiverheadTheme.brandCoral
            case .medium: return RiverheadTheme.brandGold
            case .watch: return RiverheadTheme.brandSky
            }
        }
    }

    private struct LiabilitySignal: Identifiable {
        let id = UUID()
        let title: String
        let level: ExposureLevel
        let icon: String
        let whereToLook: String
        let whyItCanHide: String
        let budgetTrigger: String
        let question: String
    }

    private struct ReviewStep: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let icon: String
    }

    private struct AuditedLiability: Identifiable {
        let id = UUID()
        let title: String
        let basis: String
        let amount: String
        let share: String
        let color: Color
    }

    private var auditedLiabilities: [AuditedLiability] {
        [
            .init(
                title: "OPEB",
                basis: "GASB 75 retiree health",
                amount: "$152,597,117",
                share: "87%",
                color: RiverheadTheme.brandCoral
            ),
            .init(
                title: "PFRS",
                basis: "GASB 68 police/fire pension",
                amount: "$15,905,643",
                share: "9%",
                color: RiverheadTheme.brandSky
            ),
            .init(
                title: "ERS",
                basis: "GASB 68 pension",
                amount: "$6,650,744",
                share: "4%",
                color: RiverheadTheme.brandMint
            )
        ]
    }

    private var signals: [LiabilitySignal] {
        [
            .init(
                title: "Retiree health and other post-employment benefits",
                level: .high,
                icon: "cross.case.fill",
                whereToLook: "2023 audited financial statements, GASB 75 OPEB actuarial notes, health-insurance trend assumptions, and retiree census changes.",
                whyItCanHide: "The yearly budget often shows only current benefit payments, while the longer retiree-health promise sits in audit disclosures and actuarial schedules. Riverhead's 2023 audit shows OPEB at $152.6M, about 87% of the combined OPEB and pension liability snapshot. The Town paid $3.55M in 2023 for 211 retirees' health coverage — about $17,000 each — while 306 employees were still active.",
                budgetTrigger: "Health-insurance premiums rise faster than the levy, retiree counts climb, or contribution assumptions change.",
                question: "What is the latest actuarial liability, and how much of the annual cost is being deferred?"
            ),
            .init(
                title: "Compensated absences and separation payouts",
                level: .medium,
                icon: "calendar.badge.clock",
                whereToLook: "Union contracts, exempt leave policies, payroll accrual reports, and retirement/resignation payout history.",
                whyItCanHide: "Unused vacation, sick, terminal leave, longevity, or contract separation benefits may not show as a department line until employees leave.",
                budgetTrigger: "A cluster of retirements or senior exits converts accrued time into cash in one budget year.",
                question: "What is the current leave-bank exposure by bargaining unit and exempt staff?"
            ),
            .init(
                title: "Pending claims, tax certiorari, and litigation",
                level: .high,
                icon: "exclamationmark.triangle.fill",
                whereToLook: "Audit contingencies, executive-session settlement approvals, risk-retention fund activity, counsel invoices, and tax-certiorari reserves.",
                whyItCanHide: "Potential settlements can be discussed as contingencies until they become probable, approved, or paid.",
                budgetTrigger: "A settlement, judgment, refund, or insurance deductible lands outside the normal operating forecast.",
                question: "Which claims are reasonably possible, and which ones have probable dollar ranges?"
            ),
            .init(
                title: "BAN rollover and conversion pressure",
                level: .medium,
                icon: "building.columns.fill",
                whereToLook: "Debt schedules, capital-project fund notes, BAN maturity dates, interest-rate resets, and board resolutions.",
                whyItCanHide: "Short-term notes can feel temporary until they roll, convert to bonds, or create recurring debt service.",
                budgetTrigger: "A BAN approaches its legal life, rates reset upward, grants fail to arrive, or principal is not reduced.",
                question: "Which BANs need payoff or conversion, and what annual debt service would follow?"
            ),
            .init(
                title: "Lease, developer, and operating commitments",
                level: .watch,
                icon: "doc.text.fill",
                whereToLook: "Executed leases, project agreements, purchase options, maintenance commitments, host-community terms, and utility-recovery provisions.",
                whyItCanHide: "The public may see a capital deal first, while future lease, maintenance, staffing, or utility costs arrive later.",
                budgetTrigger: "A project opens, possession changes, reimbursement falls short, or a utility line absorbs third-party use.",
                question: "What recurring operating cost is created after the project or agreement starts?"
            ),
            .init(
                title: "Labor-contract retroactivity and successor bargaining",
                level: .medium,
                icon: "person.3.sequence.fill",
                whereToLook: "Expired contracts, MOAs, payroll retro runs, health-premium side letters, and overtime work-rule changes.",
                whyItCanHide: "A current-year budget may carry placeholder growth while retroactive settlements create catch-up checks later.",
                budgetTrigger: "Contracts settle after budget adoption or include retroactive wage, stipend, or health-benefit changes.",
                question: "How much retroactive payroll would be owed under each plausible settlement path?"
            ),
            .init(
                title: "Environmental, asset-closure, and remediation exposure",
                level: .watch,
                icon: "leaf.fill",
                whereToLook: "Landfill or facility closure notes, environmental reviews, fuel-tank records, DEC correspondence, and capital maintenance backlogs.",
                whyItCanHide: "A site condition can sit outside the operating budget until a permit, inspection, sale, or capital project forces action.",
                budgetTrigger: "Required remediation, closure work, or engineering study becomes unavoidable.",
                question: "Which sites have known conditions that are not yet in a funded capital plan?"
            )
        ]
    }

    private var reviewSteps: [ReviewStep] {
        [
            .init(
                title: "Separate booked liabilities from watch-list exposure",
                detail: "Booked items belong in financial statements. Watch-list items need public tracking even when the exact dollar amount is not yet fixed.",
                icon: "square.stack.3d.up"
            ),
            .init(
                title: "Ask for the range, timing, and trigger",
                detail: "A useful disclosure says what could happen, when it might hit, and what decision or event would turn it into a budget cost.",
                icon: "slider.horizontal.3"
            ),
            .init(
                title: "Tie each item to a funding path",
                detail: "Reserves, insurance, grants, debt, fees, or levy support should be identified before the cost becomes urgent.",
                icon: "arrow.triangle.branch"
            )
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                auditedSnapshot
                snapshotStrip
                signalList
                reviewChecklist
                disclosurePrompt
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Off-Balance Liabilities")
        .navigationBarTitleDisplayMode(.inline)
        .adMobBannerPlacement(showDebugPlaceholder: true)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Possible Off-Balance Exposure", systemImage: "magnifyingglass.circle.fill")
                .font(.headline)
                .foregroundStyle(RiverheadTheme.brandNavy)

            Text("This view flags costs that may not appear as a simple current-year department line but can still become real budget pressure.")
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            Text("Use it as a public-question checklist, not as a claim that every item is already a booked liability. The next step is to match each signal to the latest audit note, contract, claim schedule, or board action.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RiverheadTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private var auditedSnapshot: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("2023 Audit Snapshot", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(RiverheadTheme.brandNavy)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("$175,153,504")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(RiverheadTheme.brandNavy)
                    .minimumScaleFactor(0.72)
                    .lineLimit(1)

                Text("combined OPEB and pension liabilities")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Verified as of December 31, 2023 in the Town's audited financial statements (the most recent audit available). OPEB is the dominant exposure because retiree healthcare is typically handled on a pay-as-you-go basis rather than through a funded investment trust like NYSLRS.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(auditedLiabilities) { liability in
                    auditedLiabilityRow(liability)
                }
            }

            Text("Accounting note: the 2024 ES1 Sewer hospitalization spike is consistent with a non-cash GASB 75/OPEB actuarial allocation through an enterprise-fund benefit account, not normal insurance payments. The audit trail should identify the exact allocation entry.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)

            Divider()
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 8) {
                Text("Bonded Debt Watch")
                    .font(.subheadline.weight(.semibold))

                HStack(spacing: 10) {
                    debtMetric(title: "Outstanding", value: "$38.42M", tint: RiverheadTheme.brandNavy)
                    debtMetric(title: "YoY Change", value: "-$5.54M", tint: RiverheadTheme.brandGold)
                    debtMetric(title: "Change", value: "-12.6%", tint: RiverheadTheme.brandCoral)
                }

                Text("Riverhead's 2025 Annual Financial Report shows total bonded debt outstanding falling by about $5.54M, or 12.6%, since no new bonds were issued during the year — every existing bond and BAN, including the enterprise-fund water and sewer debt that had driven 2024's increase, simply paid down principal on its existing schedule.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RiverheadTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private var snapshotStrip: some View {
        HStack(spacing: 10) {
            miniMetric(title: "High Watch", value: "\(signals.filter { $0.level == .high }.count)", tint: RiverheadTheme.brandCoral)
            miniMetric(title: "Medium", value: "\(signals.filter { $0.level == .medium }.count)", tint: RiverheadTheme.brandGold)
            miniMetric(title: "Review Steps", value: "\(reviewSteps.count)", tint: RiverheadTheme.brandSky)
        }
    }

    private var signalList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Liability Signals")
                .font(.title3.weight(.semibold))

            ForEach(signals) { signal in
                signalCard(signal)
            }
        }
    }

    private var reviewChecklist: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review Discipline")
                .font(.title3.weight(.semibold))

            ForEach(reviewSteps) { step in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: step.icon)
                        .font(.headline)
                        .foregroundStyle(RiverheadTheme.brandSky)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.subheadline.weight(.semibold))
                        Text(step.detail)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RiverheadTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(RiverheadTheme.softBorder, lineWidth: 1)
                )
            }
        }
    }

    private var disclosurePrompt: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Board-Level Question")
                .font(.headline)

            Text("For each possible exposure, can the Town show the source document, the latest estimated range, the likely fiscal year, and the funding source if it becomes payable?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RiverheadTheme.brandGold.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(RiverheadTheme.brandGold.opacity(0.35), lineWidth: 1)
        )
    }

    private func signalCard(_ signal: LiabilitySignal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: signal.icon)
                    .font(.title3)
                    .foregroundStyle(signal.level.color)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(signal.title)
                            .font(.headline)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 8)

                        Text(signal.level.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(signal.level.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(signal.level.color.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    detailRow("Where to look", signal.whereToLook)
                    detailRow("Why it can hide", signal.whyItCanHide)
                    detailRow("Budget trigger", signal.budgetTrigger)
                    detailRow("Question", signal.question, tint: signal.level.color)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RiverheadTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private func miniMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.75)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RiverheadTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private func debtMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.72)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func auditedLiabilityRow(_ liability: AuditedLiability) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(liability.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(liability.title)
                    .font(.subheadline.weight(.semibold))
                Text(liability.basis)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 2) {
                Text(liability.amount)
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                Text(liability.share)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(liability.color)
            }
        }
        .padding(12)
        .background(liability.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func detailRow(_ label: String, _ value: String, tint: Color = .secondary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        OffBalanceLiabilitiesView()
    }
}
