import SwiftUI

struct TaxBillParityDocument: Decodable, Sendable {
    let schemaVersion: Int
    let title: String
    let asOf: String
    let intro: String
    let rateSource: Source
    let rates2026: Rates
    let rates2025: Rates
    let equalization: Equalization
    let levyFunds: [LevyFund]
    let levyTotal: Double

    struct Source: Decodable, Sendable {
        let title: String
        let url: String
        let note: String
    }

    struct Rates: Decodable, Sendable {
        let generalFund: Double
        let highway: Double
        let streetLighting: Double
        let totalTownWide: Double
    }

    struct Equalization: Decodable, Sendable {
        let residentialAssessmentRatio: Double
        let asOfYear: Int
        let source: String
        let note: String
    }

    struct LevyFund: Decodable, Identifiable, Sendable {
        let code: String
        let name: String
        let description: String
        let taxLevy2026: Double
        let source: String

        var id: String { code }
    }
}

private enum TaxBillInputMode: String, CaseIterable, Identifiable {
    case assessed = "Assessed value"
    case market = "Market value"

    var id: String { rawValue }
}

private struct TaxBillEstimate {
    let generalFund: Double
    let highway: Double
    let streetLighting: Double
    let total: Double
}

@MainActor
struct NativeTaxBillParityView: View {
    @State private var document: TaxBillParityDocument?
    @State private var loadFailed = false
    @State private var inputMode: TaxBillInputMode = .assessed
    @State private var assessedValue = 45_000.0
    @State private var marketValue = 550_000.0
    @State private var starReduction = 0.0

    private static let contractURL = URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/data/tax-bill-parity.json")!
    private static let webFallbackURL = URL(string: "https://rike4545.github.io/Riverhead-NY-Budget-Web-App/tax-bill/")!

    var body: some View {
        Group {
            if let document {
                content(document)
            } else if loadFailed {
                WebContentView(url: Self.webFallbackURL, title: "My Taxes")
            } else {
                ProgressView("Loading canonical tax-rate data…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("My Taxes")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadContract()
        }
    }

    @ViewBuilder
    private func content(_ data: TaxBillParityDocument) -> some View {
        let effectiveAssessed = inputMode == .assessed
            ? assessedValue
            : marketValue * (data.equalization.residentialAssessmentRatio / 100)
        let estimate2026 = estimate(
            assessedValue: effectiveAssessed,
            reduction: starReduction,
            rates: data.rates2026
        )
        let estimate2025 = estimate(
            assessedValue: effectiveAssessed,
            reduction: starReduction,
            rates: data.rates2025
        )
        let difference = estimate2026.total - estimate2025.total
        let rateChange = data.rates2026.totalTownWide - data.rates2025.totalTownWide
        let rateChangePercent = data.rates2025.totalTownWide == 0
            ? 0
            : rateChange / data.rates2025.totalTownWide * 100

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Canonical web calculation", systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RiverheadTheme.brandTeal)
                    Text(data.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(RiverheadTheme.textPrimary)
                    Text(data.intro)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .parityCard()

                VStack(alignment: .leading, spacing: 8) {
                    Text("What changed")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(RiverheadTheme.accent)
                    Text("The Town-wide rate rose from \(data.rates2025.totalTownWide, specifier: "%.3f") to \(data.rates2026.totalTownWide, specifier: "%.3f") per $1,000.")
                        .font(.headline)
                    Text("That is an increase of \(rateChange, specifier: "%.3f") per $1,000, or about \(rateChangePercent, specifier: "%.1f")%. The calculator translates that change into dollars for your property.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .parityCard()

                VStack(alignment: .leading, spacing: 12) {
                    Picker("Input", selection: $inputMode) {
                        ForEach(TaxBillInputMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if inputMode == .assessed {
                        sliderField(
                            title: "Assessed value",
                            value: $assessedValue,
                            range: 5_000...300_000,
                            step: 1_000,
                            displayValue: currency(assessedValue),
                            hint: "Use the assessed value from your tax bill or assessment notice."
                        )
                    } else {
                        sliderField(
                            title: "Market value",
                            value: $marketValue,
                            range: 200_000...1_500_000,
                            step: 10_000,
                            displayValue: currency(marketValue),
                            hint: "Estimated assessed value: \(currency(effectiveAssessed)) using Riverhead's \(data.equalization.residentialAssessmentRatio, specifier: "%.2f")% residential assessment ratio. This conversion is an approximation."
                        )
                    }

                    sliderField(
                        title: "STAR exemption reduction (if any)",
                        value: $starReduction,
                        range: 0...30_000,
                        step: 500,
                        displayValue: currency(starReduction),
                        hint: "Use the assessed-value reduction shown on your tax bill if applicable. The app does not guess a STAR amount."
                    )
                }
                .parityCard()

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("2026 Town portion (estimated)")
                            .font(.headline)
                        Spacer()
                        Text(currency(estimate2026.total))
                            .font(.title2.weight(.bold))
                            .monospacedDigit()
                    }

                    HStack {
                        Text("2025 (for comparison)")
                        Spacer()
                        Text(currency(estimate2025.total))
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    HStack {
                        Text("Change vs. 2025")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(difference >= 0 ? "+" : "")\(currency(difference))")
                            .fontWeight(.bold)
                            .foregroundStyle(difference >= 0 ? RiverheadTheme.brandCoral : RiverheadTheme.brandTeal)
                    }

                    Divider()

                    componentRow("General Fund", estimate2026.generalFund)
                    componentRow("Highway Fund", estimate2026.highway)
                    componentRow("Street Lighting", estimate2026.streetLighting)

                    Text("This estimates only the Town portion. County, school, fire, and library taxes are separate line items on the actual bill.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .parityCard()

                VStack(alignment: .leading, spacing: 10) {
                    Text("How the 2026 Town-wide property-tax levy is allocated")
                        .font(.headline)
                    Text("This is a levy-by-fund view, not a claim that the Town spends the same percentage on a particular service. Funds can also receive fees, grants, other revenues, or fund balance.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(data.levyFunds) { fund in
                        let share = data.levyTotal > 0 ? fund.taxLevy2026 / data.levyTotal : 0
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(fund.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(fund.code) · \(fund.description)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 10)
                                Text(currency(fund.taxLevy2026))
                                    .font(.caption.weight(.bold))
                                    .monospacedDigit()
                            }
                            ProgressView(value: share)
                            Text("\(share * 100, specifier: "%.1f")% of levy")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    Divider()
                    HStack {
                        Text("Total tax levy represented above")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(currency(data.levyTotal))
                            .font(.subheadline.weight(.bold))
                    }
                }
                .parityCard()

                VStack(alignment: .leading, spacing: 8) {
                    Label("Use assessed value when you can", systemImage: "house.fill")
                        .font(.headline)
                    Text("Riverhead's residential assessment ratio was \(data.equalization.residentialAssessmentRatio, specifier: "%.2f")% for the referenced roll. Market-value conversion is only an approximation; the assessed value printed on a current bill or assessment notice is the better input.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(data.equalization.note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let url = URL(string: data.rateSource.url) {
                        Link("\(data.rateSource.title) ↗", destination: url)
                            .font(.caption.weight(.bold))
                    }
                    Text(data.rateSource.note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .parityCard()
            }
            .padding()
        }
        .background(RiverheadTheme.backgroundGradient.ignoresSafeArea())
    }

    private func estimate(
        assessedValue: Double,
        reduction: Double,
        rates: TaxBillParityDocument.Rates
    ) -> TaxBillEstimate {
        let taxableThousands = max(assessedValue - reduction, 0) / 1_000
        return TaxBillEstimate(
            generalFund: taxableThousands * rates.generalFund,
            highway: taxableThousands * rates.highway,
            streetLighting: taxableThousands * rates.streetLighting,
            total: taxableThousands * rates.totalTownWide
        )
    }

    @ViewBuilder
    private func sliderField(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        displayValue: String,
        hint: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(displayValue)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RiverheadTheme.accent)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
            Text(hint)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func componentRow(_ label: String, _ value: Double) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(currency(value))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private func loadContract() async {
        do {
            let (data, response) = try await URLSession.shared.data(from: Self.contractURL)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                loadFailed = true
                return
            }
            document = try JSONDecoder().decode(TaxBillParityDocument.self, from: data)
        } catch {
            loadFailed = true
        }
    }
}

private extension View {
    func parityCard() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(uiColor: .separator).opacity(0.22))
            )
    }
}
