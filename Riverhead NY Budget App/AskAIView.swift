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

    @State private var draft = ""
    @State private var apiKeyDraft = ""
    @State private var storedAPIKey: String?
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var messages: [RiverheadAIMessage] = []

    private let service = RiverheadAIService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroCard
                keyCard
                suggestedPromptsCard
                conversationCard
                composerCard
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

                Label("Unofficial explainer. Always verify final answers with Town staff, official notices, and adopted budget documents.", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var keyCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("OpenAI API Key")
                    .font(.headline)
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Text("Your key stays on this device in the Keychain. If you already launch the app with `OPENAI_API_KEY`, you can skip saving one here.")
                    .font(.footnote)
                    .foregroundStyle(RiverheadTheme.textSecondary)

                SecureField("sk-...", text: $apiKeyDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.footnote.monospaced())
                    .padding(12)
                    .background(fieldBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                HStack(spacing: 10) {
                    Button(storedAPIKey == nil ? "Save Key" : "Update Key") {
                        saveKey()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(RiverheadTheme.accent)
                    .disabled(apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if storedAPIKey != nil {
                        Button("Remove Key", role: .destructive) {
                            removeKey()
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Text(storedAPIKey == nil
                     ? "No saved key detected."
                     : "Saved key detected. The assistant is ready to use.")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
            }
        }
    }

    private var suggestedPromptsCard: some View {
        let prompts = [
            "What changed most in Riverhead's 2026 budget?",
            "Explain Riverhead's fund balance like I'm a resident, not an accountant.",
            "Is 28.8% a reasonable target for Riverhead's fund balance?",
            "What are the best questions to ask at a budget hearing tonight?",
            "How should Riverhead use excess reserves without creating a future budget hole?"
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

                Button {
                    Task {
                        await send()
                    }
                } label: {
                    Label(isSending ? "Asking…" : "Ask Riverhead AI", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(RiverheadTheme.brandSky)
                .disabled(isSending || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
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

        let userMessage = RiverheadAIMessage(role: .user, text: trimmed)
        messages.append(userMessage)
        draft = ""
        isSending = true

        do {
            let reply = try await service.reply(
                to: trimmed,
                history: messages,
                store: store,
                apiKey: storedAPIKey
            )
            messages.append(RiverheadAIMessage(role: .assistant, text: reply))
        } catch {
            messages.removeLast()
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            draft = trimmed
        }

        isSending = false
    }
}

#Preview {
    NavigationStack {
        AskAIView()
            .environment(RBBudgetStore())
    }
}
