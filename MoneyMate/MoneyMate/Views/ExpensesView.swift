//
//  ExpensesView.swift
//  MoneyMate
//

import SwiftUI

struct ExpensesView: View {
    @EnvironmentObject private var store: DataStore
    @State private var isPresentingAdd: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if store.expenses.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No expenses yet")
                            .font(.headline)
                        Text("Tap the + to add your first expense.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button {
                            isPresentingAdd = true
                        } label: {
                            Label("Add Expense", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(store.expenses) { expense in
                            HStack {
                                Image(systemName: expense.category.systemImageName).foregroundStyle(.secondary)
                                VStack(alignment: .leading) {
                                    Text(expense.title).font(.headline)
                                    Text(expense.date, style: .date).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("$\(expense.amount, specifier: "%.2f")")
                            }
                        }
                        .onDelete(perform: store.deleteExpenses)
                    }
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: {
                    #if os(iOS)
                    .topBarTrailing
                    #else
                    .automatic
                    #endif
                }()) {
                    Button(action: { isPresentingAdd = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAdd) {
                AddExpenseView(isPresented: $isPresentingAdd)
                    .environmentObject(store)
            }
        }
    }
}

private struct AddExpenseView: View {
    @EnvironmentObject private var store: DataStore
    @Binding var isPresented: Bool

    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var category: ExpenseCategory = .other
    @State private var notes: String = ""
    @State private var budgetAlert: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Amount", text: $amount)
                        .numericKeyboard()
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.systemImageName).tag(cat)
                        }
                    }
                    TextField("Notes (optional)", text: $notes)
                }
            }
            .navigationTitle("Add Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .alert("Budget Alert", isPresented: Binding(get: { budgetAlert != nil }, set: { if !$0 { budgetAlert = nil } })) {
                Button("OK") { budgetAlert = nil; isPresented = true == true ? false : false }
            } message: {
                Text(budgetAlert ?? "")
            }
        }
    }

    private var isValid: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return Double(amount) != nil
    }

    private func save() {
        guard let amountValue = Double(amount) else { return }
        // Check daily limit before adding
        let projectedToday = store.todaySpend() + amountValue
        let dailyLimit = store.settings.dailyMaxSpend
        if dailyLimit > 0 {
            if projectedToday > dailyLimit {
                budgetAlert = "Adding this would exceed your daily limit ($\(Int(projectedToday)) / $\(Int(dailyLimit)))."
                return
            } else if projectedToday / dailyLimit >= 0.9 {
                budgetAlert = "You're nearing your daily limit ($\(Int(projectedToday)) / $\(Int(dailyLimit)))."
                return
            }
        }
        let expense = Expense(title: title, amount: amountValue, date: date, category: category, notes: notes.isEmpty ? nil : notes)
        store.addExpense(expense)
        // Evaluate budget status for the selected category
        if let limit = store.budgets.first(where: { $0.category == category })?.monthlyLimit, limit > 0 {
            let spend = store.currentMonthSpend(for: category)
            if spend > limit {
                budgetAlert = "You've exceeded your \(category.displayName) budget. ($\(Int(spend)) / $\(Int(limit)))"
                return
            } else if spend / limit >= 0.9 {
                budgetAlert = "You're nearing your \(category.displayName) budget. ($\(Int(spend)) / $\(Int(limit)))"
                return
            }
        }
        isPresented = false
    }
}

#Preview {
    ExpensesView().environmentObject(DataStore.preview())
}


