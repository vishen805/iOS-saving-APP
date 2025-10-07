//
//  DataStore.swift
//  MoneyMate
//
//  ObservableObject store with JSON persistence.
//

import Foundation
import Combine
import SwiftUI

final class DataStore: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var goals: [SavingsGoal] = []
    @Published var budgets: [BudgetCategoryLimit] = []
    @Published var badges: [Badge] = []
    @Published var challenges: [Challenge] = []
    @Published var settings: AppSettings = AppSettings(dailyMaxSpend: 0, hasSeenOnboarding: false)

    private let autosaveDebounceSeconds: TimeInterval = 0.8
    private var cancellables: Set<AnyCancellable> = []

    init() {
        load()
        setupAutosave()
    }

    func addExpense(_ expense: Expense) { expenses.insert(expense, at: 0) }
    func deleteExpenses(at offsets: IndexSet) { expenses.remove(atOffsets: offsets) }
    func upsertGoal(_ goal: SavingsGoal) {
        if let idx = goals.firstIndex(where: { $0.id == goal.id }) { goals[idx] = goal } else { goals.append(goal) }
    }
    func deleteGoals(at offsets: IndexSet) { goals.remove(atOffsets: offsets) }
    func upsertBudget(_ limit: BudgetCategoryLimit) {
        if let idx = budgets.firstIndex(where: { $0.category == limit.category }) { budgets[idx] = limit } else { budgets.append(limit) }
    }

    func currentMonthSpend(for category: ExpenseCategory, calendar: Calendar = .current) -> Double {
        guard let range = calendar.dateInterval(of: .month, for: Date()) else { return 0 }
        return expenses.filter { $0.category == category && range.contains($0.date) }.reduce(0) { $0 + $1.amount }
    }

    func todaySpend(calendar: Calendar = .current) -> Double {
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? Date()
        let range = DateInterval(start: start, end: end)
        return expenses.filter { range.contains($0.date) }.reduce(0) { $0 + $1.amount }
    }

    func nearingLimitCategories(threshold: Double = 0.9) -> [BudgetCategoryLimit] {
        budgets.filter { limit in
            guard limit.monthlyLimit > 0 else { return false }
            let spend = currentMonthSpend(for: limit.category)
            return spend / limit.monthlyLimit >= threshold && spend <= limit.monthlyLimit
        }
    }

    func exceededLimitCategories() -> [BudgetCategoryLimit] {
        budgets.filter { limit in
            guard limit.monthlyLimit > 0 else { return false }
            return currentMonthSpend(for: limit.category) > limit.monthlyLimit
        }
    }

    // MARK: - Persistence
    private func setupAutosave() {
        let publishers: [AnyPublisher<Void, Never>] = [
            $expenses.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            $goals.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            $budgets.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            $badges.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            $challenges.dropFirst().map { _ in () }.eraseToAnyPublisher()
        ]
        Publishers.MergeMany(publishers)
            .debounce(for: .seconds(autosaveDebounceSeconds), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.save() }
            .store(in: &cancellables)
    }

    private var dataURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("MoneyMate.json")
    }

    func load() {
        do {
            let url = dataURL
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            let data = try Data(contentsOf: url)
            let bundle = try JSONDecoder().decode(ExportBundle.self, from: data)
            self.expenses = bundle.expenses
            self.goals = bundle.goals
            self.budgets = bundle.budgets
            self.badges = bundle.badges
            self.challenges = bundle.challenges
            if let s = bundle.settings { self.settings = s }
        } catch {
            // If corrupted, start fresh but don't crash
            self.expenses = []
            self.goals = []
            self.budgets = []
            self.badges = []
            self.challenges = []
            self.settings = AppSettings(dailyMaxSpend: 0, hasSeenOnboarding: false)
        }
    }

    func save() {
        do {
            let bundle = ExportBundle(expenses: expenses, goals: goals, budgets: budgets, badges: badges, challenges: challenges, settings: settings)
            let data = try JSONEncoder().encode(bundle)
            try data.write(to: dataURL, options: .atomic)
        } catch {
            // Intentionally ignore save errors for now
        }
    }

    // MARK: - Destructive operations
    func clearAll(deleteFile: Bool = false) {
        expenses.removeAll()
        goals.removeAll()
        budgets.removeAll()
        badges.removeAll()
        challenges.removeAll()
        settings = AppSettings(dailyMaxSpend: 0, hasSeenOnboarding: false)
        if deleteFile {
            // Remove persisted file if it exists; ignore errors
            try? FileManager.default.removeItem(at: dataURL)
        } else {
            save()
        }
    }

    // MARK: - Sample Data Helpers
    static func preview() -> DataStore {
        let store = DataStore()
        store.expenses = [
            Expense(title: "Coffee", amount: 4.5, category: .food),
            Expense(title: "Bus", amount: 2.75, category: .transport),
            Expense(title: "Movie", amount: 12.0, category: .entertainment)
        ]
        store.goals = [
            SavingsGoal(name: "Emergency Fund", targetAmount: 2000, savedAmount: 450),
            SavingsGoal(name: "Vacation", targetAmount: 1500, savedAmount: 300)
        ]
        store.budgets = [
            BudgetCategoryLimit(category: .food, monthlyLimit: 200),
            BudgetCategoryLimit(category: .transport, monthlyLimit: 120),
            BudgetCategoryLimit(category: .entertainment, monthlyLimit: 80)
        ]
        return store
    }
}


