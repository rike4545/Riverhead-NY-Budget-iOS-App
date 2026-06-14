//
//  RiverheadAIService.swift
//  Riverhead NY Budget App
//
//  Small OpenAI Responses API client for the in-app Riverhead budget assistant.
//

import Foundation
import OSLog

struct RiverheadAIMessage: Identifiable, Hashable {
    enum Role: String {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    let text: String

    init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }
}

enum RiverheadAIServiceError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case serviceError(String)
    case rateLimited(TimeInterval)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add an OpenAI API key before asking the assistant."
        case .invalidResponse:
            return "The AI service returned a response we couldn't read."
        case .serviceError(let message):
            return message
        case .rateLimited(let remaining):
            let secs = Int(remaining.rounded(.up))
            return "Please wait \(secs) second\(secs == 1 ? "" : "s") before sending another message."
        }
    }
}

struct RiverheadAIService {
    private let session: URLSession
    private let endpoint = URL(string: "https://api.openai.com/v1/responses")!

    static let maxHistoryMessages = 10
    private static let requestTimeout: TimeInterval = 30

    private static let configuredSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    init(session: URLSession = RiverheadAIService.configuredSession) {
        self.session = session
    }

    func reply(
        to prompt: String,
        history: [RiverheadAIMessage],
        store: RBBudgetStore,
        apiKey: String?
    ) async throws -> String {
        let resolvedKey = (apiKey?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty)
            ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        guard let resolvedKey else {
            throw RiverheadAIServiceError.missingAPIKey
        }

        var request = URLRequest(url: endpoint, timeoutInterval: Self.requestTimeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(resolvedKey)", forHTTPHeaderField: "Authorization")
        let instructions = await buildInstructions(store: store)
        let trimmedHistory = Array(history.suffix(Self.maxHistoryMessages))

        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": "gpt-5-mini",
            "instructions": instructions,
            "input": await buildInput(prompt: prompt, history: trimmedHistory, store: store),
            "max_output_tokens": 700
        ])

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw RiverheadAIServiceError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = parseErrorMessage(from: data)
            RBLog.ai.error("OpenAI HTTP \(http.statusCode): \(message ?? "no message")")
            throw RiverheadAIServiceError.serviceError(message ?? "The AI service returned HTTP \(http.statusCode).")
        }

        guard let text = parseOutputText(from: data)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            RBLog.ai.error("OpenAI response contained no parseable output text")
            throw RiverheadAIServiceError.invalidResponse
        }

        return text
    }

    @MainActor
    private func buildInstructions(store: RBBudgetStore) -> String {
        let years = store.documents.map(\.year)
        let minYear = years.min().map(String.init) ?? "unknown"
        let maxYear = years.max().map(String.init) ?? "unknown"
        let quickDocs = store.quickLinks
            .map { "\($0.year) \($0.title)" }
            .joined(separator: "; ")
        let featuredFunds = store.funds.prefix(10).joined(separator: "; ")
        let accountingStandards = accountingStandardsGuidance()
        let factPack = riverheadFactPack(store: store)

        return """
        You are Riverhead Budget Assistant, an unofficial in-app explainer for the Town of Riverhead, New York.

        Core role:
        - Explain Riverhead budget, tax, fund-balance, debt, and civic-governance topics in plain language.
        - Be resident-friendly first, but still numerically disciplined.
        - Prefer facts already loaded into the app over generic assumptions.
        - When the question is opinion-based, give a short answer, then explain the tradeoffs.
        - When the question is numeric, lead with the number and what it means.
        - When the question is procedural, suggest the most relevant hearing question, document, or next verification step.

        Built-in app context:
        - Budget document coverage appears to span \(minYear) through \(maxYear).
        - Featured budget documents: \(quickDocs.isEmpty ? "None listed." : quickDocs)
        - Example fund summaries loaded in the app: \(featuredFunds.isEmpty ? "Not loaded yet." : featuredFunds)
        - Current town tax illustration in app: \(formatCurrency(store.ratePerThousand)) per $1,000 of assessed value.
        - Current appropriations value in app: \(formatCurrency(store.appropriations)).
        - Estimated fund balance value in app: \(formatCurrency(store.estimatedFundBalance)).

        Important Riverhead facts currently baked into the app:
        \(factPack)

        Accounting standards and interpretation rules:
        \(accountingStandards)

        Source hierarchy:
        - First: the app's loaded budget values, recommendation cards, and historical notes.
        - Second: the Town budget documents and audited financial statements already referenced in the app.
        - Third: general municipal-finance concepts.
        - If the app likely lacks the needed source, say that plainly instead of pretending certainty.

        Required answer behavior:
        - Never imply you reviewed live web data unless the user explicitly supplied it in the app context.
        - If the user asks for legal conclusions, filing instructions, or exact official deadlines, clearly say the app is unofficial and suggest verifying with Town staff or official notices.
        - If the user asks whether something is compliant, frame it as a likely concern or likely benchmark, not a formal legal or audit determination.
        - Distinguish clearly between recurring fixes and one-time fixes.
        - Distinguish restricted, assigned, and unassigned fund balance when relevant.
        - If a claim rests on app modeling rather than a formally adopted Town policy, say "in the app's current model" or equivalent.

        Answer style:
        - Keep answers concise, organized, and easy to scan.
        - Use short paragraphs or flat bullets.
        - Explain jargon in plain English.
        - Avoid sounding like official legal or financial advice.
        - When helpful, end with one practical follow-up question residents could ask at a hearing.
        """
    }

    private func accountingStandardsGuidance() -> String {
        [
            "- Treat this app as discussing local-government accounting and budgeting in a general public-sector sense, especially GASB-style fund accounting and GAAP-oriented concepts.",
            "- Distinguish budgetary terms from accounting terms. A budget appropriation is not automatically the same thing as an expense, and a levy is not the same thing as total revenue.",
            "- When discussing fund balance, apply GASB Statement 54 classification language: nonspendable, restricted, committed, assigned, and unassigned. Only unassigned fund balance is truly discretionary. Do not imply that all fund balance is freely spendable.",
            "- Be careful with one-time resources. Do not present one-time fund balance draws, asset sales, TANs, RANs, or temporary financing as a structurally recurring solution for recurring operating costs.",
            "- When the user asks about financial health, discuss recurring revenues versus recurring expenditures, reserve levels, liquidity, debt burden, and operational sustainability — the same core indicators NYS OSC tracks in its Fiscal Stress Monitoring System (FSMS).",
            "- When discussing enterprise-style or special funds, note that different funds can have different legal and accounting purposes; avoid suggesting money can simply be moved without policy or legal review.",
            "- Distinguish interfund loans (must be repaid with interest, governed by the OSC Accounting Reference Manual ARM Chapter 6) from interfund transfers (permanent, one-way moves). Confusing the two is a common local-government audit finding in New York.",
            "- If a question involves recognition timing, explain that cash timing and accounting recognition may differ, and that final treatment depends on the Town's audited statements and accounting policies. The budgetary basis and GAAP basis can produce different results for the same fiscal year.",
            "- If a user asks whether a practice is 'allowed' or 'compliant,' frame the answer as a likely accounting concern, not a final professional determination.",
            "- Debt instruments: TANs (Tax Anticipation Notes) and RANs (Revenue Anticipation Notes) are short-term borrowing tools used to bridge cash gaps before tax or revenue receipts arrive. BANs (Bond Anticipation Notes) fund capital work before permanent bonds are sold. Budget notes and deficiency notes signal operating budget failures and trigger OSC notification requirements. Over-reliance on TANs is itself an FSMS warning indicator.",
            "- Multiyear financial planning: OSC recommends municipalities project revenues and expenditures three to five years out. A budget balanced in year one can still mask a structural gap if pension costs, debt service, and contract obligations are growing faster than revenues.",
            "- The NYS OSC Financial Toolkit at osc.ny.gov/local-government/financial-toolkit is the authoritative free resource for local government financial management. Key publications include: Understanding the Budget Process, GASB 54 Fund Balance Reporting, Reserve Funds, Multiyear Financial Planning, Investing and Protecting Public Funds, and the Accounting Reference Manual. The app's Budget Explainers screen now surfaces these resources directly.",
            "- When possible, suggest the most relevant official source to verify: adopted budget, audited financial statements, notes to the financials, bond documents, OSC guidance publications, or Town staff."
        ]
        .joined(separator: "\n")
    }

    @MainActor
    private func riverheadFactPack(store: RBBudgetStore) -> String {
        let fundBalancePercent = store.appropriations > 0 ? store.estimatedFundBalance / store.appropriations : 0
        let target288Balance = store.appropriations * 0.288
        let deployableAbove288 = max(0, store.estimatedFundBalance - target288Balance)

        return [
            "- 2026 General Fund appropriations in the app: \(formatCurrency(store.appropriations)).",
            "- 2026 estimated unassigned General Fund balance in the app: \(formatCurrency(store.estimatedFundBalance)), about \(formatPercent(fundBalancePercent)).",
            "- The app currently treats 15% as Riverhead's local floor, notes GFOA's two-month benchmark as about 16.7% to 17%, and presents 25% to 32% as a practical Riverhead operating range.",
            "- The app's featured reserve reset lowers Riverhead from about 41.1% to 28.8%, leaving about \(formatCurrency(deployableAbove288)) of one-time deployment capacity before specific uses are assigned.",
            "- The app's current policy story says recurring revenues should cover recurring costs, including modeled union salary pressure, without leaning on one-time reserve draws.",
            "- The app highlights a 2026 General Fund mismatch of about $74,283 and reserve dependence in sewer and water funds based on the 2026 supplement.",
            "- The app's current recommendations include a Schedule of Fund Balance and Projections with every budget, exact debit-or-credit line citations for fiscally impactful legislation, and Brookhaven-style expenditure growth triggers tied to revenue and population growth.",
            "- The app notes that Riverhead's December 5, 2006 Town Board agenda included Resolution #1101 for adoption of a General Fund balance policy, and later audited statements describe a 15% General Fund minimum by resolution.",
            "- The app's historical extraction for the 2011 adopted budget shows General Fund appropriations of $42,383,100, appropriated fund balance of $2,600,000, and tax levy of $29,250,500.",
            "- The app's current recommendation package also includes CPF debt acceleration, Community Housing Fund oversight, and phased implementation steps for immediate actions, first 100 days, and year one."
        ]
        .joined(separator: "\n")
    }

    @MainActor
    private func buildInput(prompt: String, history: [RiverheadAIMessage], store: RBBudgetStore) -> String {
        let recentHistory = history.suffix(6)
            .map { message in
                let speaker = message.role == .user ? "Resident" : "Assistant"
                return "\(speaker): \(message.text)"
            }
            .joined(separator: "\n\n")

        let responseFrame = """
        Preferred answer pattern:
        1. Start with the direct answer in one or two sentences.
        2. If numbers matter, show the most relevant numbers plainly.
        3. If the app's information is incomplete, say what is missing.
        4. If useful, end with one practical hearing question or next step.
        """

        if recentHistory.isEmpty {
            return """
            \(responseFrame)

            Current quick context:
            - App appropriations: \(formatCurrency(store.appropriations))
            - App estimated fund balance: \(formatCurrency(store.estimatedFundBalance))
            - App policy floor / upper target: \(formatPercent(store.fundBalancePolicy.minimumPercent)) / \(formatPercent(store.fundBalancePolicy.targetUpperPercent ?? 0))

            Resident question:
            \(prompt)
            """
        }

        return """
        \(responseFrame)

        Recent conversation:

        \(recentHistory)

        Resident question:
        \(prompt)
        """
    }

    private func parseOutputText(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        if let outputText = object["output_text"] as? String, !outputText.isEmpty {
            return outputText
        }

        guard let output = object["output"] as? [[String: Any]] else {
            return nil
        }

        var parts: [String] = []

        for item in output {
            guard item["type"] as? String == "message",
                  let content = item["content"] as? [[String: Any]] else { continue }

            for block in content {
                if let text = block["text"] as? String,
                   let type = block["type"] as? String,
                   type == "output_text" {
                    parts.append(text)
                }
            }
        }

        return parts.isEmpty ? nil : parts.joined(separator: "\n\n")
    }

    private func parseErrorMessage(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        if let error = object["error"] as? [String: Any],
           let message = error["message"] as? String,
           !message.isEmpty {
            return message
        }

        return nil
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }

    private func formatPercent(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "\(value * 100)%"
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
