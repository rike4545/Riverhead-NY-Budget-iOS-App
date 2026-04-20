//
//  ContractImpactEstimatorView.swift
//  Riverhead NY Budget App
//
//  Created by Bryan on 1/15/26.
//


import SwiftUI

public struct ContractImpactEstimatorView: View {

    @State private var startYear: Int = 2024
    @State private var endYear: Int = 2029

    @State private var includeTotalBudget: Bool = false
    @State private var baselineTotalBudget: Double = 0

    @State private var groups: [GroupAssumptions] = [
        .init(group: .pba, baseYear: 2024, basePayroll: 0, fte: 0, overtimeRate: 0.10, otherCompRate: 0.00, otherCompFlatPerFTE: 0, benefitsPerFTE: 0, benefitsInflationRate: 0.06, fallbackWageGrowth: 0.02),
        .init(group: .soa, baseYear: 2024, basePayroll: 0, fte: 0, overtimeRate: 0.08, otherCompRate: 0.00, otherCompFlatPerFTE: 0, benefitsPerFTE: 0, benefitsInflationRate: 0.06, fallbackWageGrowth: 0.02),
        .init(group: .csea, baseYear: 2024, basePayroll: 0, fte: 0, overtimeRate: 0.05, otherCompRate: 0.00, otherCompFlatPerFTE: 0, benefitsPerFTE: 0, benefitsInflationRate: 0.06, fallbackWageGrowth: 0.02),
        .init(group: .exempt, baseYear: 2024, basePayroll: 0, fte: 0, overtimeRate: 0.00, otherCompRate: 0.00, otherCompFlatPerFTE: 0, benefitsPerFTE: 0, benefitsInflationRate: 0.06, fallbackWageGrowth: 0.02)
    ]

    private let engine = ContractImpactEngine()

    public init() {}

    public var body: some View {
        List {
            Section("Scope") {
                Stepper("Start Year: \(startYear)", value: $startYear, in: 2000...2100)
                Stepper("End Year: \(endYear)", value: $endYear, in: 2000...2100)

                Toggle("Model total town budget impact", isOn: $includeTotalBudget)

                if includeTotalBudget {
                    TextField("Baseline Total Budget", value: $baselineTotalBudget, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                } else {
                    Text("Tip: If you only care about contract pressure, focus on personnel % increase.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Group assumptions (enter your adopted baseline payroll)") {
                ForEach($groups) { $g in
                    NavigationLink {
                        GroupEditor(group: $g)
                            .navigationTitle(g.group.displayName)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(g.group.displayName).font(.headline)
                            HStack {
                                Text("Base \(g.baseYear): \(g.basePayroll, format: .currency(code: "USD"))")
                                Spacer()
                                Text("FTE: \(g.fte, format: .number.precision(.fractionLength(1)))")
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Results") {
                let results = engine.estimate(
                    groups: groups,
                    startYear: startYear,
                    endYear: endYear,
                    baselineTotalBudget: includeTotalBudget ? baselineTotalBudget : nil
                )

                if results.isEmpty {
                    Text("No results (check year range).")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(results) { r in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("\(r.year)").font(.headline)
                                Spacer()
                                Text(r.totalPersonnelCost, format: .currency(code: "USD"))
                                    .font(.headline)
                            }

                            if let pct = r.yoyPersonnelPct {
                                Text("Personnel YoY: \(pct, format: .percent.precision(.fractionLength(2)))  (\((r.yoyPersonnelDelta ?? 0), format: .currency(code: "USD")))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Personnel YoY: —")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            if includeTotalBudget, let b = r.totalBudgetCost, let bpct = r.yoyBudgetPct {
                                Text("Total Budget YoY: \(bpct, format: .percent.precision(.fractionLength(2)))  (\((r.yoyBudgetDelta ?? 0), format: .currency(code: "USD")))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Text("Total Budget: \(b, format: .currency(code: "USD"))")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            DisclosureGroup("By group") {
                                ForEach(LaborGroup.allCases, id: \.self) { g in
                                    if let v = r.groupTotalCost[g] {
                                        HStack {
                                            Text(g.displayName)
                                            Spacer()
                                            Text(v, format: .currency(code: "USD"))
                                        }
                                        .font(.footnote)
                                    }
                                }
                            }
                            .font(.footnote)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Notes") {
                Text("This estimator is designed for budget planning: it models wage actions + optional OT/other comp loads + benefits. For best accuracy, enter baseline payroll that already reflects any mid-year contract adjustments in your adopted budget year.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Contract Impact Estimator")
    }
}

private struct GroupEditor: View {
    @Binding var group: GroupAssumptions

    var body: some View {
        Form {
            Section("Baseline") {
                Stepper("Base Year: \(group.baseYear)", value: $group.baseYear, in: 2000...2100)
                TextField("Base Payroll (annual)", value: $group.basePayroll, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                TextField("FTE", value: $group.fte, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
            }

            Section("Loads") {
                TextField("Overtime rate (e.g., 0.12 = 12%)", value: $group.overtimeRate, format: .number.precision(.fractionLength(3)))
                    .keyboardType(.decimalPad)
                TextField("Other comp rate (e.g., 0.05 = 5%)", value: $group.otherCompRate, format: .number.precision(.fractionLength(3)))
                    .keyboardType(.decimalPad)
                TextField("Other comp flat per FTE ($/yr)", value: $group.otherCompFlatPerFTE, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
            }

            Section("Benefits") {
                TextField("Benefits per FTE ($/yr)", value: $group.benefitsPerFTE, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                TextField("Benefits inflation (e.g., 0.06 = 6%)", value: $group.benefitsInflationRate, format: .number.precision(.fractionLength(3)))
                    .keyboardType(.decimalPad)
            }

            Section("Unknown years policy") {
                TextField("Fallback wage growth (e.g., 0.02 = 2%)", value: $group.fallbackWageGrowth, format: .number.precision(.fractionLength(3)))
                    .keyboardType(.decimalPad)
                Text("Used only if a year has no explicit contract action for this group.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
