//
//  AskAIView.swift
//  Riverhead NY Budget App
//
//  Resident-friendly AI explainer for Riverhead budget and civic questions.
//

import SwiftUI

@MainActor
struct AskAIView: View {
    @Environment(RBBudgetStore.self) private var store
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var draft = ""
    @State private var apiKeyDraft = ""
    @State private var storedAPIKey: String?
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var messages: [RiverheadAIMessage] = []
    @State private var lastSentAt: Date?
    @State private var showClearConfirm = false

    private static let sendCooldown: TimeInterval = 5
    private let service = RiverheadAIService()

    private var canSend: Bool {
        guard !isSending, !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        if let last = lastSentAt { return Date().timeIntervalSince(last) >= Self.sendCooldown }
        return true
    }
    private var isAccessibilityLayout: Bool { dynamicTypeSize.isAccessibilitySize }
    private var hasLiveAIKey: Bool {
        storedAPIKey != nil
        || ProcessInfo.processInfo.environment["OPENAI_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    init(initialPrompt: String = "") {
        _draft = State(initialValue: initialPrompt)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroCard
                suggestedPromptsCard
                conversationCard
                composerCard
                liveAISetupDisclosure
            }
            .padding(16)
        }
        .background(RiverheadTheme.Surface.page.ignoresSafeArea())
        .navigationTitle("Ask AI")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadStoredKey()
        }
        .alert("AI Assistant", isPresented: keyAlertIsPresented, actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "")
        })
    }

    private var heroCard: some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Resident Budget Assistant")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Text("Ask grounded questions about Riverhead's budget, fund balance, tax pressure, debt, and hearing strategy in plain English.")
                    .font(.subheadline)
                    .foregroundStyle(RiverheadTheme.textSecondary)

                aiModeStatus

                Label("Unofficial explainer. Always verify final answers with Town staff, official notices, and adopted budget documents.", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var aiModeStatus: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: hasLiveAIKey ? "network.badge.shield.half.filled" : "lock.doc.fill")
                .font(.subheadline)
                .foregroundStyle(hasLiveAIKey ? RiverheadTheme.brandMint : RiverheadTheme.brandGold)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(hasLiveAIKey ? "Live AI mode available" : "Local demo mode")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Text(hasLiveAIKey
                     ? "Questions can use the configured OpenAI key, with answers still framed as unofficial."
                     : "No key is needed. The assistant will answer from built-in app values and show its source trail.")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .background(fieldBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(RiverheadTheme.softBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var liveAISetupDisclosure: some View {
        card {
            DisclosureGroup {
                keyCardContent
                    .padding(.top, 12)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "key.horizontal.fill")
                        .foregroundStyle(RiverheadTheme.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Live AI setup")
                            .font(.headline)
                            .foregroundStyle(RiverheadTheme.textPrimary)

                        Text(hasLiveAIKey ? "A live key is available." : "Optional. Local demo answers work without this.")
                            .font(.caption)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                    }
                }
            }
            .tint(RiverheadTheme.accent)
        }
    }

    private var keyCardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OpenAI API Key")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RiverheadTheme.textPrimary)

            Text("Your key stays on this device in the Keychain. This is intended for development or power-user use, not as a requirement for residents.")
                .font(.footnote)
                .foregroundStyle(RiverheadTheme.textSecondary)

            Label("Without a key, the assistant uses a local demo answer based on values already loaded in the app.", systemImage: "wand.and.stars")
                .font(.caption)
                .foregroundStyle(RiverheadTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            SecureField("sk-...", text: $apiKeyDraft)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.footnote.monospaced())
                .padding(12)
                .background(fieldBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityLabel("OpenAI API key")
                .accessibilityHint("Your key is stored in Keychain on this device.")

            ViewThatFits(in: .horizontal) {
                keyActions(vertical: false)
                keyActions(vertical: true)
            }

            Text(storedAPIKey == nil
                 ? "No saved key detected."
                 : "Saved key detected. Live answers are available.")
                .font(.caption)
                .foregroundStyle(RiverheadTheme.textSecondary)
        }
    }

    private var suggestedPromptsCard: some View {
        let prompts = [
            "What changed most in Riverhead's 2026 budget?",
            "Explain Riverhead's fund balance like I'm a resident, not an accountant.",
            "Is 28.8% a reasonable target for Riverhead's fund balance?",
            "What are the best questions to ask at a budget hearing tonight?",
            "How should Riverhead use excess reserves without creating a future budget hole?",
            "Which budget signals in this app look most important, and why?"
        ]

        return card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Try asking")
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)

                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        draft = prompt
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(RiverheadTheme.accent)
                            Text(prompt)
                                .font(.footnote)
                                .foregroundStyle(RiverheadTheme.textPrimary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(12)
                        .background(fieldBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Suggested prompt: \(prompt)")
                    .accessibilityHint("Copies this prompt into the question field.")
                }
            }
        }
    }

    private var conversationCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Conversation")
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)

                if messages.isEmpty {
                    ContentUnavailableView(
                        "No messages yet",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Ask about fund balance, the tax levy, debt, overtime, salary pressure, or what the Town should explain better.")
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(messages) { message in
                        messageBubble(message)
                    }

                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("Clear Conversation", systemImage: "trash")
                            .font(.footnote)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .confirmationDialog("Clear all messages?", isPresented: $showClearConfirm, titleVisibility: .visible) {
                        Button("Clear", role: .destructive) { messages = [] }
                        Button("Cancel", role: .cancel) {}
                    }
                }

                if isSending {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Thinking through your Riverhead question…")
                            .font(.footnote)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                    }
                    .padding(12)
                }
            }
        }
    }

    private var composerCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ask a question")
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)

                TextEditor(text: $draft)
                    .frame(minHeight: 120)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(fieldBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityLabel("Question")
                    .accessibilityHint("Type a Riverhead budget or civic question.")

                Button {
                    Task {
                        await send()
                    }
                } label: {
                    Label(
                        isSending ? "Asking…" : (hasLiveAIKey ? "Ask Riverhead AI" : "Get Demo Answer"),
                        systemImage: hasLiveAIKey ? "paperplane.fill" : "doc.text.magnifyingglass"
                    )
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(RiverheadTheme.brandSky)
                .disabled(!canSend)
                .accessibilityInputLabels(["Ask Riverhead AI", "Ask AI", "Send question"])

                Text(hasLiveAIKey
                     ? "Live answers use the configured key and should still be verified against official sources."
                     : "Demo answers do not call a network service. They use app-loaded budget values and a source trail.")
                    .font(.caption2)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func keyActions(vertical: Bool) -> some View {
        Group {
            if vertical || isAccessibilityLayout {
                VStack(alignment: .leading, spacing: 10) {
                    keyActionButtons
                }
            } else {
                HStack(spacing: 10) {
                    keyActionButtons
                }
            }
        }
    }

    @ViewBuilder
    private var keyActionButtons: some View {
        Button(storedAPIKey == nil ? "Save Key" : "Update Key") {
            saveKey()
        }
        .buttonStyle(.borderedProminent)
        .tint(RiverheadTheme.accent)
        .disabled(apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .accessibilityInputLabels([storedAPIKey == nil ? "Save key" : "Update key", "OpenAI key"])

        if storedAPIKey != nil {
            Button("Remove Key", role: .destructive) {
                removeKey()
            }
            .buttonStyle(.bordered)
            .accessibilityInputLabels(["Remove key", "Delete key"])
        }
    }

    private var fieldBackground: Color {
        scheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.8)
    }

    private var keyAlertIsPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func messageBubble(_ message: RiverheadAIMessage) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(message.role == .user ? "You" : "Riverhead AI")
                .font(.caption.weight(.semibold))
                .foregroundStyle(message.role == .user ? RiverheadTheme.brandSky : RiverheadTheme.brandNavy)

            Text(message.text)
                .font(.footnote)
                .foregroundStyle(RiverheadTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(message.role == .user ? RiverheadTheme.brandSky.opacity(0.12) : fieldBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(RiverheadTheme.softBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.role == .user ? "You said: \(message.text)" : "Riverhead AI said: \(message.text)")
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(RiverheadTheme.Surface.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(RiverheadTheme.softBorder, lineWidth: 1)
        )
    }

    private func loadStoredKey() {
        let key = OpenAIKeychain.loadAPIKey()
        storedAPIKey = key
        apiKeyDraft = key ?? ""
    }

    private func saveKey() {
        let trimmed = apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if OpenAIKeychain.saveAPIKey(trimmed) {
            storedAPIKey = trimmed
            apiKeyDraft = trimmed
        } else {
            errorMessage = "Could not save the API key to the Keychain."
        }
    }

    private func removeKey() {
        guard OpenAIKeychain.deleteAPIKey() else {
            errorMessage = "Could not remove the API key from the Keychain."
            return
        }

        storedAPIKey = nil
        apiKeyDraft = ""
    }

    private func send() async {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let last = lastSentAt, Date().timeIntervalSince(last) < Self.sendCooldown {
            let remaining = Self.sendCooldown - Date().timeIntervalSince(last)
            errorMessage = RiverheadAIServiceError.rateLimited(remaining).errorDescription
            return
        }

        let userMessage = RiverheadAIMessage(role: .user, text: trimmed)
        messages.append(userMessage)
        draft = ""
        isSending = true
        lastSentAt = Date()

        do {
            let reply = try await service.reply(
                to: trimmed,
                history: messages,
                store: store,
                apiKey: storedAPIKey
            )
            messages.append(RiverheadAIMessage(role: .assistant, text: reply))
        } catch RiverheadAIServiceError.missingAPIKey {
            messages.append(RiverheadAIMessage(role: .assistant, text: demoReply(for: trimmed)))
        } catch {
            messages.removeLast()
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            draft = trimmed
        }

        isSending = false
    }

    private func demoReply(for prompt: String) -> String {
        let reservePercent = store.appropriations > 0 ? store.estimatedFundBalance / store.appropriations : 0
        let deployableAboveFloor = max(0, store.estimatedFundBalance - store.minimumRequired)

        return """
        Demo answer, using only values already loaded in the app:

        Riverhead's current app model shows General Fund appropriations of \(store.appropriations.formatted(.currency(code: "USD").precision(.fractionLength(0)))) and estimated unassigned fund balance of \(store.estimatedFundBalance.formatted(.currency(code: "USD").precision(.fractionLength(0)))), or about \(reservePercent.formatted(.percent.precision(.fractionLength(1)))) of appropriations.

        The practical takeaway: reserves appear above the local minimum, but one-time reserves should not be treated as recurring revenue for salaries, debt service, or ongoing operations. The cushion above the modeled minimum is about \(deployableAboveFloor.formatted(.currency(code: "USD").precision(.fractionLength(0)))) before considering restrictions, assignments, or policy choices.

        Source trail: this demo used the app's loaded budget store values and fund-balance policy model. For formal use, verify against the adopted budget, audited statements, and Town staff.

        Hearing question: Which parts of this proposal are recurring costs, and which parts are paid with one-time resources?

        Your question was: "\(prompt)"
        """
    }
}

#Preview {
    NavigationStack {
        AskAIView()
            .environment(RBBudgetStore())
    }
}
