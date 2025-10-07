//
//  GoalsView.swift
//  MoneyMate
//

import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var store: DataStore
    @State private var isPresentingAdd: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if store.goals.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "flag")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No goals yet")
                            .font(.headline)
                        Text("Tap the + to set your first savings goal.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button { isPresentingAdd = true } label: {
                            Label("Add Goal", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
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
                            }
                        }
                        .onDelete(perform: store.deleteGoals)
                    }
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: {
                    #if os(iOS)
                    .topBarTrailing
                    #else
                    .automatic
                    #endif
                }()) {
                    Button(action: { isPresentingAdd = true }) { Image(systemName: "plus.circle.fill") }
                }
            }
            .sheet(isPresented: $isPresentingAdd) {
                AddGoalView(isPresented: $isPresentingAdd).environmentObject(store)
            }
        }
    }
}

private struct AddGoalView: View {
    @EnvironmentObject private var store: DataStore
    @Binding var isPresented: Bool

    @State private var name: String = ""
    @State private var targetAmount: String = ""
    @State private var savedAmount: String = ""
    @State private var deadline: Date? = nil
    @State private var hasDeadline: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Name", text: $name)
                    TextField("Target amount", text: $targetAmount).numericKeyboard()
                    TextField("Already saved", text: $savedAmount).numericKeyboard()
                    Toggle("Set deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Deadline", selection: Binding(get: { deadline ?? Date() }, set: { deadline = $0 }), displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { isPresented = false } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!isValid) }
            }
        }
    }

    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard Double(targetAmount) != nil else { return false }
        guard savedAmount.isEmpty || Double(savedAmount) != nil else { return false }
        return true
    }

    private func save() {
        let goal = SavingsGoal(name: name,
                               targetAmount: Double(targetAmount) ?? 0,
                               savedAmount: Double(savedAmount) ?? 0,
                               deadline: deadline)
        store.upsertGoal(goal)
        isPresented = false
    }
}

#Preview {
    GoalsView().environmentObject(DataStore.preview())
}


