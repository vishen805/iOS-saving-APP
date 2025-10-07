//
//  DashboardView.swift
//  MoneyMate
//

import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject private var store: DataStore
    @State private var showingOnboarding: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section("Savings Goals") {
                    ForEach(store.goals) { goal in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(goal.name).font(.headline)
                                Spacer()
                                Text("$\(Int(goal.savedAmount)) / $\(Int(goal.targetAmount))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            ProgressView(value: goal.progress)
                                .tint(.green)
                            Text(motivationalMessage(for: goal)).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Visuals") {
                    ChartsSectionView()
                        .environmentObject(store)
                }

                if let alert = budgetAlertText() {
                    Section("Budget Alerts") {
                        Text(alert).foregroundStyle(.orange)
                    }
                }

                Section("Quick Tips") {
                    Text(AITips.simpleTip(store: store))
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: {
                    #if os(iOS)
                    .topBarTrailing
                    #else
                    .automatic
                    #endif
                }()) {
                    Button {
                        showingOnboarding = true
                    } label: {
                        Label("How to Use", systemImage: "questionmark.circle")
                    }
                }
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView().environmentObject(store)
            }
            .onAppear {
                if !store.settings.hasSeenOnboarding { showingOnboarding = true }
            }
        }
    }

    private func motivationalMessage(for goal: SavingsGoal) -> String {
        let pct = Int(round(goal.progress * 100))
        switch pct {
        case 0..<25: return "Great start! Keep adding to build momentum."
        case 25..<50: return "Nice! You're a quarter of the way there."
        case 50..<75: return "Halfway there—stay consistent!"
        case 75..<100: return "So close! A final push will do it."
        default: return "Goal reached—awesome work!"
        }
    }

    private func budgetAlertText() -> String? {
        let nearing = store.nearingLimitCategories()
        let exceeded = store.exceededLimitCategories()
        var parts: [String] = []
        if !nearing.isEmpty {
            let list = nearing.map { $0.category.displayName }.joined(separator: ", ")
            parts.append("Nearing limit: \(list)")
        }
        if !exceeded.isEmpty {
            let list = exceeded.map { $0.category.displayName }.joined(separator: ", ")
            parts.append("Exceeded: \(list)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }
}

#Preview {
    DashboardView().environmentObject(DataStore.preview())
}


