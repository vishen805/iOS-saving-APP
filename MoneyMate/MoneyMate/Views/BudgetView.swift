//
//  BudgetView.swift
//  MoneyMate
//

import SwiftUI

struct BudgetView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        NavigationStack {
            List {
                Section("Daily Limit") {
                    let today = store.todaySpend()
                    let limit = store.settings.dailyMaxSpend
                    let progress = limit > 0 ? min(today / limit, 1) : 0
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(limit > 0 ? "Today: $\(Int(today)) / $\(Int(limit))" : "Today: $\(Int(today))")
                                .foregroundStyle(limit > 0 && today > limit ? .red : .primary)
                            Spacer()
                            Button("Set") { isPresentingDailyLimit = true }
                        }
                        ProgressView(value: progress)
                            .tint(today > limit ? .red : .green)
                    }
                }
                ForEach(ExpenseCategory.allCases) { cat in
                    let current = store.currentMonthSpend(for: cat)
                    let limit = store.budgets.first(where: { $0.category == cat })?.monthlyLimit ?? 0
                    let progress = limit > 0 ? min(current / limit, 1) : 0
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label(cat.displayName, systemImage: cat.systemImageName)
                            Spacer()
                            Text(limit > 0 ? "$\(Int(current)) / $\(Int(limit))" : "$\(Int(current))")
                                .foregroundStyle(limit > 0 && current > limit ? .red : .secondary)
                        }
                        ProgressView(value: progress)
                            .tint(current > limit ? .red : .blue)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Set Limit") { selected = cat }
                    }
                }
            }
            .navigationTitle("Budget")
            .sheet(item: $selected) { cat in
                SetLimitView(category: cat)
                    .environmentObject(store)
            }
        }
        .sheet(isPresented: $isPresentingDailyLimit) {
            SetDailyLimitView(isPresented: $isPresentingDailyLimit)
                .environmentObject(store)
        }
    }

    @State private var selected: ExpenseCategory? = nil
    @State private var isPresentingDailyLimit: Bool = false
}

private struct SetLimitView: View {
    @EnvironmentObject private var store: DataStore
    let category: ExpenseCategory
    @State private var limit: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Monthly Limit")) {
                    TextField("Amount", text: $limit).numericKeyboard()
                }
            }
            .navigationTitle(category.displayName)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(Double(limit) == nil) }
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .onAppear {
                if let existing = store.budgets.first(where: { $0.category == category }) {
                    limit = String(existing.monthlyLimit)
                }
            }
        }
    }

    private func save() {
        let value = Double(limit) ?? 0
        store.upsertBudget(BudgetCategoryLimit(category: category, monthlyLimit: value))
        dismiss()
    }
}

private struct SetDailyLimitView: View {
    @EnvironmentObject private var store: DataStore
    @Binding var isPresented: Bool
    @State private var limit: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Maximum Spend") {
                    TextField("Amount", text: $limit).numericKeyboard()
                }
            }
            .navigationTitle("Daily Limit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { isPresented = false } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(Double(limit) == nil) }
            }
            .onAppear { limit = store.settings.dailyMaxSpend == 0 ? "" : String(store.settings.dailyMaxSpend) }
        }
    }

    private func save() {
        store.settings.dailyMaxSpend = Double(limit) ?? 0
        isPresented = false
    }
}

#Preview {
    BudgetView().environmentObject(DataStore.preview())
}


