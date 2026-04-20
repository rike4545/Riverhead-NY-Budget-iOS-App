import SwiftUI

struct LegalDefamationAnalysisView: View {
    let originalStatement: String = "Employee not hirable due to poor reputation at same company (Town of Riverhead)"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                sectionCard(
                    title: "Original Statement",
                    content: originalStatement
                )

                sectionCard(
                    title: "Legal Issue",
                    content: """
This statement may imply undisclosed facts about the individual's professional reputation, which creates potential defamation risk under New York law.
"""
                )

                sectionCard(
                    title: "Key Legal Principles",
                    content: """
- Opinion is protected, but only if it does not imply hidden facts
- Statements harming employment can be defamation per se
- Context (tone, platform, audience) determines interpretation
- Public officials require proof of actual malice
"""
                )

                caseLawSection

                sectionCard(
                    title: "Risk Analysis",
                    content: """
HIGH RISK:
"Has a poor reputation" -> implies factual claim

MEDIUM RISK:
"Not hirable due to reputation"

LOWER RISK:
"Rehiring seems unlikely given circumstances"
"""
                )

                sectionCard(
                    title: "Safer Version",
                    content: """
"Based on prior association with the Town, it seems unlikely he would be rehired."
"""
                )

                sectionCard(
                    title: "Rebuttal / Defense",
                    content: """
This statement can be defended as opinion if:

- It reflects a general perception rather than a factual claim
- It does not rely on undisclosed defamatory facts
- It is presented in a public commentary context
- It avoids asserting misconduct or specific wrongdoing

However, if interpreted as a factual claim about reputation, it may still be actionable.
"""
                )
            }
            .padding()
        }
        .navigationTitle("Legal Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Defamation Risk Analysis")
                .font(.title)
                .fontWeight(.bold)

            Text("New York Law | Employment Reputation | Public Commentary")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var caseLawSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Case Law")
                .font(.headline)

            caseRow(
                name: "Steinhilber v. Alphonse (1986)",
                summary: "Distinguishes protected opinion from actionable fact"
            )

            caseRow(
                name: "Immuno AG v. Moor-Jankowski (1991)",
                summary: "Context and tone determine whether speech is opinion"
            )

            caseRow(
                name: "Gross v. NY Times (1993)",
                summary: "Mixed opinion implying hidden facts is not protected"
            )

            caseRow(
                name: "Liberman v. Gelstein (1992)",
                summary: "Statements harming profession are defamation per se"
            )

            caseRow(
                name: "NY Times v. Sullivan (1964)",
                summary: "Public officials must prove actual malice"
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func sectionCard(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            Text(content)
                .font(.body)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func caseRow(name: String, summary: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(summary)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        LegalDefamationAnalysisView()
    }
}
