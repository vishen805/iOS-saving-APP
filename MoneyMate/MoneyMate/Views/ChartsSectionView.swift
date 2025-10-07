//
//  ChartsSectionView.swift
//  MoneyMate
//

import SwiftUI
import Charts

struct ChartsSectionView: View {
    @EnvironmentObject private var store: DataStore

    private struct CategorySlice: Identifiable {
        let id = UUID()
        let category: ExpenseCategory
        let total: Double
    }

    private struct DaySpend: Identifiable {
        let id = UUID()
        let date: Date
        let total: Double
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending by Category (This Month)").font(.headline)
            Chart(categorySlices()) { slice in
                SectorMark(
                    angle: .value("Total", slice.total),
                    innerRadius: .ratio(0.5),
                    angularInset: 1
                )
                .foregroundStyle(by: .value("Category", slice.category.displayName))
            }
            .frame(height: 220)

            Text("Daily Spend (Last 30 Days)").font(.headline)
            Chart(daySpends()) { point in
                BarMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Amount", point.total)
                )
            }
            .frame(height: 220)
        }
    }

    private func categorySlices() -> [CategorySlice] {
        guard let monthRange = Calendar.current.dateInterval(of: .month, for: Date()) else { return [] }
        return ExpenseCategory.allCases.compactMap { cat in
            let total = store.expenses
                .filter { $0.category == cat && monthRange.contains($0.date) }
                .reduce(0) { $0 + $1.amount }
            return total > 0 ? CategorySlice(category: cat, total: total) : nil
        }
    }

    private func daySpends() -> [DaySpend] {
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: -29, to: cal.startOfDay(for: Date())) else { return [] }
        let end = Date()
        let range = DateInterval(start: start, end: end)
        let filtered = store.expenses.filter { range.contains($0.date) }
        let grouped = Dictionary(grouping: filtered) { cal.startOfDay(for: $0.date) }
        return stride(from: 0, through: 29, by: 1).compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: offset, to: start) else { return nil }
            let total = grouped[day]?.reduce(0) { $0 + $1.amount } ?? 0
            return DaySpend(date: day, total: total)
        }
    }
}

#Preview {
    ChartsSectionView().environmentObject(DataStore.preview())
}


