//
//  ProfileView.swift
//  MoneyMate
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct ProfileView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        NavigationStack {
            List {
                Section("Badges") {
                    if store.badges.isEmpty {
                        Text("No badges earned yet.").foregroundStyle(.secondary)
                    } else {
                        ForEach(store.badges) { badge in
                            HStack {
                                Image(systemName: "star.circle.fill").foregroundStyle(.yellow)
                                VStack(alignment: .leading) {
                                    Text(badge.name)
                                    Text(badge.earnedDate, style: .date).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Section("Backup & Export") {
                    NavigationLink("Export CSVs", destination: ExportView())
                    NavigationLink("Import Expenses CSV", destination: ImportExpensesView())
                }

                Section("Danger Zone") {
                    NavigationLink("Delete All Data", destination: DangerZoneView())
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

private struct ExportView: View {
    @EnvironmentObject private var store: DataStore
    @State private var exportResult: String = ""

    var body: some View {
        Form {
            Section("Export Expenses") {
                Button("Copy Expenses CSV to Clipboard") {
                    let csv = CSVExporter.expensesCSV(store.expenses)
                    copyToClipboard(csv)
                    exportResult = "Expenses CSV copied to clipboard"
                }
            }
            Section("Export Goals") {
                Button("Copy Goals CSV to Clipboard") {
                    let csv = CSVExporter.goalsCSV(store.goals)
                    copyToClipboard(csv)
                    exportResult = "Goals CSV copied to clipboard"
                }
            }
            if !exportResult.isEmpty {
                Text(exportResult).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Export")
    }

    private func copyToClipboard(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        #else
        // Unsupported platform; no-op
        #endif
    }
}

#Preview {
    ProfileView().environmentObject(DataStore.preview())
}

private struct ImportExpensesView: View {
    @EnvironmentObject private var store: DataStore
    @State private var csvText: String = ""
    @State private var result: String = ""

    var body: some View {
        Form {
            Section("Paste CSV (id,title,amount,date,category,notes)") {
                TextEditor(text: $csvText).frame(minHeight: 160)
            }
            Button("Import") { importCSV() }
                .disabled(csvText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if !result.isEmpty { Text(result).foregroundStyle(.secondary) }
        }
        .navigationTitle("Import Expenses")
    }

    private func importCSV() {
        let lines = csvText.split(separator: "\n").map(String.init)
        guard !lines.isEmpty else { result = "No data"; return }
        let dataLines = lines.dropFirst() // assume header
        let formatter = ISO8601DateFormatter()
        var imported = 0
        for line in dataLines {
            let cols = parseCSVRow(line)
            guard cols.count >= 6 else { continue }
            let title = cols[1]
            let amount = Double(cols[2]) ?? 0
            let date = formatter.date(from: cols[3]) ?? Date()
            let category = ExpenseCategory(rawValue: cols[4]) ?? .other
            let notes = cols[5].isEmpty ? nil : cols[5]
            store.addExpense(Expense(title: title, amount: amount, date: date, category: category, notes: notes))
            imported += 1
        }
        result = "Imported \(imported) expenses"
    }

    private func parseCSVRow(_ row: String) -> [String] {
        var values: [String] = []
        var current = ""
        var inQuotes = false
        for char in row {
            if char == "\"" {
                
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                values.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        values.append(current)
        return values.map { $0.replacingOccurrences(of: "\"\"", with: "\"") }
    }
}

private struct DangerZoneView: View {
    @EnvironmentObject private var store: DataStore
    @State private var confirmBackupChecked: Bool = false
    @State private var confirmUnderstandChecked: Bool = false
    @State private var confirmTypeText: String = ""
    @State private var alsoDeleteFile: Bool = false
    @State private var didDelete: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Before you delete") {
                Toggle("I have exported a backup (recommended)", isOn: $confirmBackupChecked)
                Toggle("I understand this action is irreversible", isOn: $confirmUnderstandChecked)
            }
            Section("Type to confirm") {
                Text("Type DELETE to confirm")
                TextField("Type here", text: $confirmTypeText)
            }
            Section("Options") {
                Toggle("Also remove on-disk backup file", isOn: $alsoDeleteFile)
            }
            Section {
                Button(role: .destructive) {
                    store.clearAll(deleteFile: alsoDeleteFile)
                    didDelete = true
                } label: {
                    Text("Delete All Data")
                }
                .disabled(!canDelete)
            }

            if didDelete {
                Text("All data cleared.").foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Delete All Data")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
        }
    }

    private var canDelete: Bool {
        confirmUnderstandChecked && confirmTypeText.uppercased() == "DELETE"
    }
}


