//
//  DepartmentsView.swift
//  Riverhead NY Budget App
//
//  Community-built directory of Town departments.
//  Unofficial helper: links to public resources only.
//

import SwiftUI

// MARK: - Model

struct RHDepartment: Identifiable {
    let id = UUID()
    let name: String
    let summary: String

    /// Display string (may include extension)
    let phoneDisplay: String?
    /// Digits-only dial target (no extension)
    let phoneDial: String?

    let website: URL?
    let email: String?
    let systemImage: String

    /// Optional: show a contextual budget tool link for relevant departments.
    let showsContractImpactTool: Bool
}

// MARK: - View

@MainActor
struct DepartmentsView: View {
    @Environment(\.openURL) private var openURL

    @State private var showContractImpactEstimator = false

    private let departments: [RHDepartment] = [
        RHDepartment(
            name: "Supervisor’s Office / Town Board",
            summary: "Town-wide leadership, meetings, and local laws.",
            phoneDisplay: "631-727-3200 x655",
            phoneDial: "6317273200",
            website: URL(string: "https://www.townofriverheadny.gov/"),
            email: nil,
            systemImage: "person.2.circle",
            showsContractImpactTool: false
        ),

        // ✅ New: Finance/Budget entry (logical home for the estimator link)
        RHDepartment(
            name: "Budget & Finance",
            summary: "Budget questions, financial reports, and fiscal administration.",
            phoneDisplay: "631-727-3200",
            phoneDial: "6317273200",
            website: URL(string: "https://www.townofriverheadny.gov/"),
            email: nil,
            systemImage: "chart.pie.fill",
            showsContractImpactTool: true
        ),

        RHDepartment(
            name: "Clerk’s Office",
            summary: "Records, marriage licenses, FOIL requests, and meeting agendas.",
            phoneDisplay: "631-727-3200",
            phoneDial: "6317273200",
            website: URL(string: "https://www.townofriverheadny.gov/Directory.aspx?DID=9"),
            email: nil,
            systemImage: "doc.text.fill",
            showsContractImpactTool: false
        ),
        RHDepartment(
            name: "Tax Receiver",
            summary: "Property tax payments, receipts, and basic bill questions.",
            phoneDisplay: "631-727-3200",
            phoneDial: "6317273200",
            website: URL(string: "https://www.townofriverheadny.gov/Directory.aspx?DID=19"),
            email: nil,
            systemImage: "dollarsign.circle.fill",
            showsContractImpactTool: false
        ),
        RHDepartment(
            name: "Building & Code Enforcement",
            summary: "Permits, inspections, and property maintenance code issues.",
            phoneDisplay: "631-727-3200 x213",
            phoneDial: "6317273200",
            website: URL(string: "https://www.townofriverheadny.gov/Directory.aspx?DID=7"),
            email: nil,
            systemImage: "hammer.fill",
            showsContractImpactTool: false
        ),
        RHDepartment(
            name: "Planning Department",
            summary: "Planning, zoning, and development projects.",
            phoneDisplay: "631-727-3200",
            phoneDial: "6317273200",
            website: URL(string: "https://www.townofriverheadny.gov/Directory.aspx?DID=13"),
            email: nil,
            systemImage: "map.fill",
            showsContractImpactTool: false
        ),
        RHDepartment(
            name: "Highway Department",
            summary: "Road maintenance, snow removal, and related issues.",
            phoneDisplay: "631-727-3200 x228",
            phoneDial: "6317273200",
            website: URL(string: "https://www.townofriverheadny.gov/Directory.aspx?DID=21"),
            email: nil,
            systemImage: "car.fill",
            showsContractImpactTool: false
        ),
        RHDepartment(
            name: "Sanitation / Garbage",
            summary: "Collection schedules, transfer station, and disposal info.",
            phoneDisplay: "631-727-3200",
            phoneDial: "6317273200",
            website: URL(string: "https://www.townofriverheadny.gov/220/Sanitation"),
            email: nil,
            systemImage: "trash.fill",
            showsContractImpactTool: false
        ),
        RHDepartment(
            name: "Parks & Recreation",
            summary: "Parks, beaches, programs, and seasonal events.",
            phoneDisplay: "631-727-3200 x205",
            phoneDial: "6317273200",
            website: URL(string: "https://www.townofriverheadny.gov/203/Parks-Recreation"),
            email: nil,
            systemImage: "figure.walk",
            showsContractImpactTool: false
        ),
        RHDepartment(
            name: "Police Department",
            summary: "Emergency response, non-emergency assistance, and records.",
            phoneDisplay: "631-727-4500 (non-emergency)",
            phoneDial: "6317274500",
            website: URL(string: "https://www.townofriverheadny.gov/165/Police-Department"),
            email: nil,
            systemImage: "shield.lefthalf.fill",
            showsContractImpactTool: false
        )
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(departments) { dept in
                        departmentRow(dept)
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("This is an unofficial community helper.")
                        Text("For the most current and official information, please use the Town of Riverhead directory.")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Town Departments")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showContractImpactEstimator) {
                NavigationStack {
                    ContractImpactEstimatorView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showContractImpactEstimator = false }
                            }
                        }
                }
            }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func departmentRow(_ dept: RHDepartment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: dept.systemImage)
                    .font(.system(size: 24))
                    .frame(width: 36, height: 36)
                    .padding(8)
                    .background(.secondary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(dept.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)

                    Text(dept.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                if let dial = dept.phoneDial,
                   let url = URL(string: "tel://\(dial)"),
                   let display = dept.phoneDisplay {
                    Button { openURL(url) } label: {
                        Label(display, systemImage: "phone.fill")
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .buttonStyle(.bordered)
                }

                if let website = dept.website {
                    Button { openURL(website) } label: {
                        Label("Website", systemImage: "safari")
                            .lineLimit(1)
                    }
                    .buttonStyle(.borderedProminent)
                }

                if let email = dept.email,
                   let url = URL(string: "mailto:\(email)") {
                    Button { openURL(url) } label: {
                        Label("Email", systemImage: "envelope.fill")
                            .lineLimit(1)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .font(.footnote)
            .accessibilityElement(children: .combine)

            // ✅ Contextual placement: only under Budget & Finance
            if dept.showsContractImpactTool {
                Button {
                    showContractImpactEstimator = true
                } label: {
                    Label("Open Contract Impact Estimator", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .padding(.top, 2)
                .accessibilityHint("Opens a budgeting tool to estimate the impact of labor contracts.")
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DepartmentsView()
    }
}
