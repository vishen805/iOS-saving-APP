//
//  Models.swift
//  MoneyMate
//
//  Core domain models for the app.
//

import Foundation

enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {
    case food, transport, entertainment, utilities, shopping, health, housing, education, other
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .food: return "Food"
        case .transport: return "Transport"
        case .entertainment: return "Entertainment"
        case .utilities: return "Utilities"
        case .shopping: return "Shopping"
        case .health: return "Health"
        case .housing: return "Housing"
        case .education: return "Education"
        case .other: return "Other"
        }
    }
    var systemImageName: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .entertainment: return "film.fill"
        case .utilities: return "bolt.fill"
        case .shopping: return "bag.fill"
        case .health: return "heart.fill"
        case .housing: return "house.fill"
        case .education: return "book.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

struct Expense: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var amount: Double
    var date: Date
    var category: ExpenseCategory
    var notes: String?

    init(id: UUID = UUID(), title: String, amount: Double, date: Date = Date(), category: ExpenseCategory, notes: String? = nil) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.notes = notes
    }
}

struct SavingsGoal: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var targetAmount: Double
    var savedAmount: Double
    var deadline: Date?

    init(id: UUID = UUID(), name: String, targetAmount: Double, savedAmount: Double = 0, deadline: Date? = nil) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.savedAmount = savedAmount
        self.deadline = deadline
    }

    var progress: Double { guard targetAmount > 0 else { return 0 }; return min(savedAmount / targetAmount, 1) }
}

struct BudgetCategoryLimit: Identifiable, Codable, Hashable {
    let id: UUID
    var category: ExpenseCategory
    var monthlyLimit: Double

    init(id: UUID = UUID(), category: ExpenseCategory, monthlyLimit: Double) {
        self.id = id
        self.category = category
        self.monthlyLimit = monthlyLimit
    }
}

struct Badge: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var earnedDate: Date
}

struct Challenge: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var isCompleted: Bool
}

struct ExportBundle: Codable {
    var expenses: [Expense]
    var goals: [SavingsGoal]
    var budgets: [BudgetCategoryLimit]
    var badges: [Badge]
    var challenges: [Challenge]
    var settings: AppSettings?
}

struct AppSettings: Codable, Hashable {
    var dailyMaxSpend: Double
    var hasSeenOnboarding: Bool
}


