//
//  ContentView.swift
//  Riverhead NY
//
//  Budget home / landing screen.
//  - Dark-mode friendly, no harsh glare
//  - Card-based “I’m here to…” journeys
//  - Re-emphasizes community-built / unofficial status
//

import SwiftUI

@MainActor
struct ContentView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        headerHero

                        // “I’m here to…” journey cards
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What would you like to do?")
                                .font(.headline)
                                .foregroundStyle(RiverheadTheme.textPrimary)

                            NavigationLink {
                                ExploreView()
                            } label: {
                                actionCard(
                                    title: "Explore the 2026 Budget",
                                    subtitle: "Browse funds, departments, and line items with plain-language context.",
                                    icon: "doc.text.magnifyingglass"
                                )
                            }

                            NavigationLink {
                                FundBalancePoliciesView()
                            } label: {
                                actionCard(
                                    title: "Understand Fund Balance Policies",
                                    subtitle: "See how Riverhead and similar towns set reserve targets — and why it matters.",
                                    icon: "checklist"
                                )
                            }

                            NavigationLink {
                                RiverheadFundBalanceAuditView()
                            } label: {
                                actionCard(
                                    title: "Check Fund Balance Health",
                                    subtitle: "Compare policy targets vs. actual balances over time.",
                                    icon: "shield.checkerboard"
                                )
                            }

                            NavigationLink {
                                HistoricalTabView()
                            } label: {
                                actionCard(
                                    title: "Review History & Trends",
                                    subtitle: "Look back at levies, tax rates, and major budget shifts.",
                                    icon: "clock.arrow.circlepath"
                                )
                            }
                        }

                        // Resident tools
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tools")
                                .font(.headline)
                                .foregroundStyle(RiverheadTheme.textPrimary)

                            NavigationLink {
                                MyTaxesView()
                            } label: {
                                actionCard(
                                    title: "Estimate My Town Tax",
                                    subtitle: "Roughly estimate your Town portion and see how every dollar is allocated.",
                                    icon: "house.and.flag"
                                )
                            }

                            infoCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
                .navigationTitle("Riverhead Budget")
                .navigationBarTitleDisplayMode(.inline)
                .task {
                    await BudgetDataBootstrapper.warmUpAsync()
                }
            }
        }
    }

    // MARK: - Header

    private var headerHero: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Riverhead Budget Helper")
                            .font(.system(.title2, design: .rounded).weight(.semibold))
                            .foregroundStyle(RiverheadTheme.textPrimary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(2)

                        Text("A community-built guide to understanding the Town of Riverhead’s adopted budget — in plain language.")
                            .font(.footnote)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    // Little “pill” to reinforce unofficial status
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Community helper")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(scheme == .dark
                                          ? Color.white.opacity(0.08)
                                          : Color.black.opacity(0.04))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(borderColor.opacity(0.6), lineWidth: 0.5)
                            )

                        Text("Unofficial")
                            .font(.caption2)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                    }
                }

                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .imageScale(.medium)
                        .foregroundStyle(RiverheadTheme.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Adopted 2026 Budget Focus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RiverheadTheme.textPrimary)

                        Text("Figures and views in this app generally reflect the Town’s adopted 2026 budget, where available.")
                            .font(.caption)
                            .foregroundStyle(RiverheadTheme.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Action Cards

    private func actionCard(
        title: String,
        subtitle: String,
        icon: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(RiverheadTheme.accent)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(RiverheadTheme.accent.opacity(scheme == .dark ? 0.22 : 0.14))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RiverheadTheme.textSecondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(borderColor.opacity(0.6), lineWidth: 0.7)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(
            color: .black.opacity(scheme == .dark ? 0.4 : 0.10),
            radius: scheme == .dark ? 10 : 4,
            x: 0,
            y: scheme == .dark ? 6 : 2
        )
    }

    // MARK: - Info Card

    private var infoCard: some View {
        card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Not an official app")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RiverheadTheme.textPrimary)

                Text("This is an independent, community-built tool. It does not replace the Town’s official budget documents, public notices, or tax bills.")
                    .font(.caption)
                    .foregroundStyle(RiverheadTheme.textSecondary)

                Text("For official information, always refer to the Town of Riverhead’s website, adopted budgets, local laws, and audited financial statements.")
                    .font(.caption2)
                    .foregroundStyle(RiverheadTheme.textSecondary)
            }
        }
    }

    // MARK: - Styling helpers

    private var backgroundView: some View {
        Group {
            if scheme == .dark {
                // True dark, no glare
                RiverheadTheme.Surface.page
                    .ignoresSafeArea()
            } else {
                // Website-like gradient in light mode
                RiverheadTheme.backgroundGradient
                    .ignoresSafeArea()
            }
        }
    }

    private var cardBackgroundColor: Color {
        scheme == .dark
        ? Color.white.opacity(0.08)      // subtle, matte glass
        : RiverheadTheme.cardBackground
    }

    private var borderColor: Color {
        scheme == .dark
        ? Color.white.opacity(0.22)
        : RiverheadTheme.softBorder
    }

    /// Generic card container consistent with MoreView / NewsAndEventsView
    private func card<Content: View>(
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .shadow(
                color: .black.opacity(scheme == .dark ? 0.45 : 0.12),
                radius: 14,
                x: 0,
                y: 8
            )
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
