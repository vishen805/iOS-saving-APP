//
//  ContentView.swift
//  MoneyMate
//
//  Created by 123 on 10/7/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: DataStore

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }

            ExpensesView()
                .tabItem {
                    Label("Expenses", systemImage: "list.bullet")
                }

            GoalsView()
                .tabItem {
                    Label("Goals", systemImage: "flag.checkered")
                }

            BudgetView()
                .tabItem {
                    Label("Budget", systemImage: "creditcard")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }
}

#Preview {
    ContentView().environmentObject(DataStore.preview())
}
