//
//  CSVExporter.swift
//  MoneyMate
//

import Foundation

enum CSVExporter {
    static func expensesCSV(_ expenses: [Expense]) -> String {
        var rows: [String] = ["id,title,amount,date,category,notes"]
        let formatter = ISO8601DateFormatter()
        for e in expenses {
            let cols: [String] = [
                e.id.uuidString,
                escape(e.title),
                String(e.amount),
                formatter.string(from: e.date),
                e.category.rawValue,
                escape(e.notes ?? "")
            ]
            rows.append(cols.joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    static func goalsCSV(_ goals: [SavingsGoal]) -> String {
        var rows: [String] = ["id,name,targetAmount,savedAmount,deadline"]
        let formatter = ISO8601DateFormatter()
        for g in goals {
            let cols: [String] = [
                g.id.uuidString,
                escape(g.name),
                String(g.targetAmount),
                String(g.savedAmount),
                g.deadline.map { formatter.string(from: $0) } ?? ""
            ]
            rows.append(cols.joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    private static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\n") || value.contains("\"") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}


