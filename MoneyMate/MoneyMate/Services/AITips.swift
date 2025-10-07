//
//  AITips.swift
//  MoneyMate
//

import Foundation

enum AITips {
    static func simpleTip(store: DataStore) -> String {
        let monthlyCoffee = estimatedMonthlySpend(store: store, category: .food, keyword: "coffee")
        if monthlyCoffee > 0 {
            let yearly = Int(monthlyCoffee * 12)
            return "Cutting $\(Int(monthlyCoffee))/mo on coffee saves ~$\(yearly)/yr."
        }

        if let goal = store.goals.sorted(by: { $0.progress < $1.progress }).first {
            let remaining = max(goal.targetAmount - goal.savedAmount, 0)
            if remaining > 0 {
                let weeks = 12.0
                let perWeek = Int(ceil(remaining / weeks))
                return "Save ~$\(perWeek)/wk for 12 weeks to hit \(goal.name)."
            }
        }
        return "Skip one non-essential purchase today and add $5 to a goal."
    }

    static func reminder() -> String {
        return "Skip a treat today and move $5 to your savings goal."
    }

    private static func estimatedMonthlySpend(store: DataStore, category: ExpenseCategory, keyword: String) -> Double {
        let cal = Calendar.current
        guard let range = cal.dateInterval(of: .month, for: Date()) else { return 0 }
        let filtered = store.expenses.filter { e in
            e.category == category && range.contains(e.date) && e.title.lowercased().contains(keyword)
        }
        return filtered.reduce(0) { $0 + $1.amount }
    }
}


