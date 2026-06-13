import SwiftUI

@MainActor
struct Budget2027ExecutiveWhiteboardView: View {
    @Environment(RBBudgetStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var summary: Budget2027WhiteboardSummary {
        Budget2027WhiteboardSummary(store: store)
    }

    private var isCompact: Bool {
        horizontalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: isCompact ? 1 : 2)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                whiteboardHeader
                bottomLineCard
                pressureAndOffsetBoard
                decisionBoard
                stateBudgetPlaybook
                departmentNotes
                hearingQuestions
            }
            .padding(.horizontal, isCompact ? 12 : 18)
            .padding(.vertical, 18)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.965, green: 0.972, blue: 0.956),
                    Color(red: 0.985, green: 0.988, blue: 0.978)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("2027 Executive Summary")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var whiteboardHeader: some View {
        WhiteboardPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "pencil.and.outline")
                        .font(.title2)
                        .foregroundStyle(WhiteboardInk.blue)
                        .frame(width: 40, height: 40)
                        .background(Circle().stroke(WhiteboardInk.blue, lineWidth: 2))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Potential 2027 Budget")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(WhiteboardInk.black)

                        Text("Executive whiteboard summary")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(WhiteboardInk.blue)
                    }

                    Spacer()

                    Text("Draft")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WhiteboardInk.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .overlay(
                            Capsule()
                                .stroke(WhiteboardInk.red, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        )
                }

                Text("The short version: 2027 pressure is mostly recurring. The budget works best if Riverhead pairs any tax increase with visible recurring offsets, protects reserves for one-time needs, and explains department investments with service targets.")
                    .font(.body)
                    .foregroundStyle(WhiteboardInk.black.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var bottomLineCard: some View {
        WhiteboardPanel(title: "Bottom Line") {
            LazyVGrid(columns: columns, spacing: 12) {
                whiteboardMetric(
                    "Modeled recurring pressure",
                    value: summary.recurringPressure.currencyText,
                    note: "Payroll, pension/operating pressure, and selected service adds.",
                    tint: WhiteboardInk.red,
                    icon: "arrow.up.right.circle"
                )

                whiteboardMetric(
                    "Modeled recurring offsets",
                    value: summary.recurringOffsets.currencyText,
                    note: "Levy growth, savings discipline, and recurring revenue adds.",
                    tint: WhiteboardInk.green,
                    icon: "arrow.down.right.circle"
                )

                whiteboardMetric(
                    "Illustrative recurring gap",
                    value: summary.recurringGap.currencyText,
                    note: summary.recurringGap >= 0 ? "Offsets exceed modeled pressure." : "Needs more recurring solution before reserves.",
                    tint: summary.recurringGap >= 0 ? WhiteboardInk.green : WhiteboardInk.orange,
                    icon: summary.recurringGap >= 0 ? "checkmark.circle" : "exclamationmark.circle"
                )

                whiteboardMetric(
                    "Sample tax change",
                    value: summary.sampleTaxChange.currencyText,
                    note: "For a $450K assessed value at the app's current Town rate.",
                    tint: WhiteboardInk.blue,
                    icon: "house.and.flag"
                )
            }
        }
    }

    private var pressureAndOffsetBoard: some View {
        WhiteboardPanel(title: "What Is Moving The Budget?") {
            VStack(spacing: 14) {
                markerRow(
                    title: "Cost pressure",
                    items: [
                        .init("CSEA 2027 wage action", summary.cseaPressure, WhiteboardInk.red),
                        .init("Public safety and non-contract growth", summary.publicSafetyAndNonContractPressure, WhiteboardInk.orange),
                        .init("Pension / insurance / operating pressure", summary.otherPressure, WhiteboardInk.red),
                        .init("Core service investments", summary.serviceInvestments, WhiteboardInk.blue)
                    ]
                )

                whiteboardArrow("Recurring costs need recurring answers")

                markerRow(
                    title: "Possible offsets",
                    items: [
                        .init("Illustrative levy growth", summary.levyYield, WhiteboardInk.green),
                        .init("Savings and refill discipline", summary.recurringSavings, WhiteboardInk.green),
                        .init("Fees, rentals, and recurring revenue", summary.recurringRevenueAdds, WhiteboardInk.blue)
                    ]
                )
            }
        }
    }

    private var decisionBoard: some View {
        WhiteboardPanel(title: "Executive Decisions") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Budget2027WhiteboardDecision.decisions) { decision in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: decision.icon)
                            .foregroundStyle(decision.tint)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(decision.title)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(WhiteboardInk.black)

                            Text(decision.detail)
                                .font(.footnote)
                                .foregroundStyle(WhiteboardInk.black.opacity(0.72))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if decision.id != Budget2027WhiteboardDecision.decisions.last?.id {
                        DashedDivider()
                    }
                }
            }
        }
    }

    private var departmentNotes: some View {
        WhiteboardPanel(title: "Department Notes") {
            LazyVGrid(columns: columns, spacing: 12) {
                stickyNote("Building + Code", "Staffing and vehicles should be tied to inspection speed, complaint closure, and field coverage.", WhiteboardInk.blue)
                stickyNote("Police", "New officers should be shown beside overtime controls, workload data, and pension pressure.", WhiteboardInk.orange)
                stickyNote("Town Clerk", "Any added position should connect to transaction volume or response-time goals.", WhiteboardInk.green)
                stickyNote("Technology", "Separate one-time implementation from recurring subscription or support costs.", WhiteboardInk.purple)
            }
        }
    }

    private var stateBudgetPlaybook: some View {
        WhiteboardPanel(title: "NY State Budget Playbook") {
            VStack(alignment: .leading, spacing: 14) {
                Text("The FY 2027 State budget posture is a useful model for Riverhead: protect formal reserves, separate temporary aid from recurring aid, and make one-time funds pay for one-time stability moves.")
                    .font(.subheadline)
                    .foregroundStyle(WhiteboardInk.black.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(StateBudgetTakeaway.items) { item in
                        takeawayCard(item)
                    }
                }

                aimImpactCard
                stateSourceLinks
            }
        }
    }

    private var aimImpactCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "building.columns.fill")
                    .foregroundStyle(WhiteboardInk.blue)
                Text("AIM / TMA Impact")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(WhiteboardInk.black)
            }

            LazyVGrid(columns: columns, spacing: 10) {
                whiteboardMetric(
                    "Annual AIM",
                    value: summary.aimPayment.currencyText,
                    note: "Regular NY municipal aid payment for Riverhead.",
                    tint: WhiteboardInk.green,
                    icon: "calendar.badge.checkmark"
                )

                whiteboardMetric(
                    "Temporary municipal aid",
                    value: summary.fy2027TMAPlanningEstimate.currencyText,
                    note: "Planning estimate if FY 2027 triples the current TMA layer.",
                    tint: WhiteboardInk.orange,
                    icon: "hourglass"
                )

                whiteboardMetric(
                    "Aid vs. spending",
                    value: summary.totalStateMunicipalAidShare.formatted(.percent.precision(.fractionLength(2))),
                    note: "A helpful offset, not a structural answer to payroll growth.",
                    tint: WhiteboardInk.blue,
                    icon: "chart.pie"
                )

                whiteboardMetric(
                    "2027 planning rule",
                    value: "Separate lines",
                    note: "AIM is recurring; TMA should be treated as provisional until enacted again.",
                    tint: WhiteboardInk.purple,
                    icon: "line.3.horizontal.decrease.circle"
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(WhiteboardInk.blue.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(WhiteboardInk.blue.opacity(0.28), lineWidth: 1.2)
        )
    }

    private var stateSourceLinks: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sources to cite in budget notes")
                .font(.caption.weight(.bold))
                .foregroundStyle(WhiteboardInk.black.opacity(0.66))

            Link(destination: URL(string: "https://www.governor.ny.gov/sites/default/files/2026-01/FY2027ExecutiveBudgetBook.pdf")!) {
                Label("FY 2027 Executive Budget Book", systemImage: "doc.text.magnifyingglass")
                    .font(.caption.weight(.semibold))
            }

            Link(destination: URL(string: "https://www.governor.ny.gov/news/governor-hochul-announces-agreement-fy-2027-state-budget")!) {
                Label("FY 2027 budget agreement highlights", systemImage: "newspaper")
                    .font(.caption.weight(.semibold))
            }

            Link(destination: URL(string: "https://www.osc.ny.gov/local-government/data/aid-and-incentives-municipalities-aim-and-temporary-municipal-assistance-tma")!) {
                Label("OSC AIM / TMA municipal aid table", systemImage: "tablecells")
                    .font(.caption.weight(.semibold))
            }
        }
    }

    private func takeawayCard(_ item: StateBudgetTakeaway) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: item.icon)
                    .foregroundStyle(item.tint)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(WhiteboardInk.black)

                    Text(item.stateSignal)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(item.tint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(item.riverheadMove)
                .font(.footnote)
                .foregroundStyle(WhiteboardInk.black.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(item.tint.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(item.tint.opacity(0.34), lineWidth: 1.1)
        )
    }

    private var hearingQuestions: some View {
        WhiteboardPanel(title: "Board Room Questions") {
            VStack(alignment: .leading, spacing: 10) {
                numberedQuestion(1, "What is the cap-compliant version of the 2027 budget?")
                numberedQuestion(2, "Which costs are recurring, and which are one-time?")
                numberedQuestion(3, "What monthly metric proves overtime or vacancy savings are real?")
                numberedQuestion(4, "If reserves are used, what is the rebuild plan?")
                numberedQuestion(5, "Which department investments have measurable service targets?")

                NavigationLink {
                    Budget2027LabView()
                } label: {
                    Label("Open detailed 2027 Budget Lab", systemImage: "slider.horizontal.3")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(WhiteboardInk.blue)
                .padding(.top, 4)
            }
        }
    }

    private func whiteboardMetric(_ title: String, value: String, note: String, tint: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WhiteboardInk.black.opacity(0.72))
            }

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.72)

            Text(note)
                .font(.caption)
                .foregroundStyle(WhiteboardInk.black.opacity(0.64))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(tint.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, dash: [7, 5]))
        )
    }

    private func markerRow(title: String, items: [Budget2027WhiteboardMarker]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(WhiteboardInk.black)

            ForEach(items) { item in
                HStack(spacing: 10) {
                    Circle()
                        .fill(item.tint)
                        .frame(width: 9, height: 9)

                    Text(item.title)
                        .font(.subheadline)
                        .foregroundStyle(WhiteboardInk.black.opacity(0.82))

                    Spacer(minLength: 8)

                    Text(item.amount.currencyText)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(item.tint)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func whiteboardArrow(_ text: String) -> some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(WhiteboardInk.black.opacity(0.38))
                .frame(height: 2)
            Image(systemName: "arrow.down")
                .foregroundStyle(WhiteboardInk.black.opacity(0.62))
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(WhiteboardInk.black.opacity(0.62))
            Rectangle()
                .fill(WhiteboardInk.black.opacity(0.38))
                .frame(height: 2)
        }
    }

    private func stickyNote(_ title: String, _ detail: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(tint)
                    .frame(width: 10, height: 10)
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(WhiteboardInk.black)
            }

            Text(detail)
                .font(.footnote)
                .foregroundStyle(WhiteboardInk.black.opacity(0.74))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(tint.opacity(0.42), lineWidth: 1.2)
        )
    }

    private func numberedQuestion(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(WhiteboardInk.black.opacity(0.78)))

            Text(text)
                .font(.subheadline)
                .foregroundStyle(WhiteboardInk.black.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct WhiteboardPanel<Content: View>: View {
    let title: String?
    let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(WhiteboardInk.black)

                    Rectangle()
                        .fill(WhiteboardInk.black.opacity(0.20))
                        .frame(height: 2)
                }
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(WhiteboardInk.black.opacity(0.20), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

private struct DashedDivider: View {
    var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(height: 1)
            .overlay(
                Rectangle()
                    .stroke(WhiteboardInk.black.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
            )
    }
}

private enum WhiteboardInk {
    static let black = Color(red: 0.105, green: 0.118, blue: 0.135)
    static let blue = Color(red: 0.090, green: 0.315, blue: 0.620)
    static let green = Color(red: 0.075, green: 0.470, blue: 0.285)
    static let orange = Color(red: 0.760, green: 0.390, blue: 0.065)
    static let red = Color(red: 0.700, green: 0.105, blue: 0.105)
    static let purple = Color(red: 0.430, green: 0.235, blue: 0.645)
}

@MainActor
private struct Budget2027WhiteboardSummary {
    let store: RBBudgetStore

    let levyGrowthPercent = 3.0
    let cseaPressure = 484_395.46
    let publicSafetyAndNonContractPressure = 452_331.64
    let otherPressure = 1_260_000.0
    let recurringSavings = 806_431.97
    let recurringRevenueAdds = 61_500.0
    let serviceInvestments = 612_928.06
    let aimPayment = 107_028.0
    let currentTemporaryMunicipalAssistance = 7_487.0

    var levyYield: Double {
        store.appropriations * 0.703 * (levyGrowthPercent / 100)
    }

    var recurringPressure: Double {
        cseaPressure + publicSafetyAndNonContractPressure + otherPressure + serviceInvestments
    }

    var recurringOffsets: Double {
        levyYield + recurringSavings + recurringRevenueAdds
    }

    var recurringGap: Double {
        recurringOffsets - recurringPressure
    }

    var sampleTaxChange: Double {
        (450_000 / 1_000) * store.ratePerThousand * (levyGrowthPercent / 100)
    }

    var totalStateMunicipalAid: Double {
        aimPayment + fy2027TMAPlanningEstimate
    }

    var totalStateMunicipalAidShare: Double {
        guard store.appropriations > 0 else { return 0 }
        return totalStateMunicipalAid / store.appropriations
    }

    var fy2027TMAPlanningEstimate: Double {
        currentTemporaryMunicipalAssistance * 3
    }
}

private struct Budget2027WhiteboardMarker: Identifiable {
    let id = UUID()
    let title: String
    let amount: Double
    let tint: Color

    init(_ title: String, _ amount: Double, _ tint: Color) {
        self.title = title
        self.amount = amount
        self.tint = tint
    }
}

private struct Budget2027WhiteboardDecision: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
    let tint: Color

    static let decisions: [Budget2027WhiteboardDecision] = [
        .init(
            title: "Tax cap path",
            detail: "Show the cap-compliant baseline first, then explain exactly what any override would fund.",
            icon: "percent",
            tint: WhiteboardInk.blue
        ),
        .init(
            title: "Reserve rule",
            detail: "Use reserves for capital or transition costs, not as quiet support for recurring payroll.",
            icon: "banknote",
            tint: WhiteboardInk.green
        ),
        .init(
            title: "Savings proof",
            detail: "Tie overtime, vacancy, refill, and revenue assumptions to monthly reporting.",
            icon: "checklist.checked",
            tint: WhiteboardInk.orange
        ),
        .init(
            title: "Service targets",
            detail: "Each staffing or technology add should name the resident-facing result it buys.",
            icon: "target",
            tint: WhiteboardInk.purple
        )
    ]
}

private struct StateBudgetTakeaway: Identifiable {
    let id = UUID()
    let title: String
    let stateSignal: String
    let riverheadMove: String
    let icon: String
    let tint: Color

    static let items: [StateBudgetTakeaway] = [
        .init(
            title: "Rainy-day fund",
            stateSignal: "State playbook: keep formal reserves visible before adding new commitments.",
            riverheadMove: "Adopt a written reserve ladder: 15% floor, practical operating range, board approval below floor, and a three-year replenish schedule after any draw.",
            icon: "umbrella.fill",
            tint: WhiteboardInk.blue
        ),
        .init(
            title: "Tax stabilization fund",
            stateSignal: "State playbook: treat fiscal stability as a named policy, not leftover cash.",
            riverheadMove: "Create a separate tax-stabilization reserve or assignment above the operating target, with deposits from surplus years and withdrawals limited to levy smoothing or one-time shocks.",
            icon: "scale.3d",
            tint: WhiteboardInk.green
        ),
        .init(
            title: "AIM and TMA discipline",
            stateSignal: "State playbook: recurring aid and temporary aid are different budget facts.",
            riverheadMove: "Show AIM and TMA on separate revenue lines; use regular AIM for recurring planning and keep temporary aid out of permanent salary assumptions.",
            icon: "banknote.fill",
            tint: WhiteboardInk.orange
        ),
        .init(
            title: "State grant readiness",
            stateSignal: "State playbook: local assistance favors shovel-ready, measurable projects.",
            riverheadMove: "Keep a grant-ready capital list for roads, water, sewers, cybersecurity, housing infrastructure, and shared services with local match sources identified up front.",
            icon: "folder.badge.gearshape",
            tint: WhiteboardInk.purple
        )
    ]
}

private extension Double {
    var currencyText: String {
        formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

#Preview {
    NavigationStack {
        Budget2027ExecutiveWhiteboardView()
            .environment(RBBudgetStore())
    }
}
