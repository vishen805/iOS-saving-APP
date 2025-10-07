//
//  OnboardingView.swift
//  MoneyMate
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TabView {
                OnboardPage(image: "chart.pie.fill", title: "Track Spending", text: "Log expenses and see where your money goes.")
                OnboardPage(image: "flag.checkered", title: "Hit Savings Goals", text: "Set goals and watch your progress.")
                OnboardPage(image: "creditcard", title: "Stay on Budget", text: "Category limits and alerts when you near or exceed them.")
                OnboardPage(image: "bell", title: "Smart Reminders", text: "Get nudges and tips to save more each day.")
            }
            .modifier(PlatformPageTabStyle())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Got it") {
                        store.settings.hasSeenOnboarding = true
                        dismiss()
                    }
                }
            }
            .navigationTitle("Welcome")
        }
    }
}

private struct OnboardPage: View {
    let image: String
    let title: String
    let text: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: image).font(.system(size: 56))
            Text(title).font(.title2).bold()
            Text(text).multilineTextAlignment(.center).foregroundStyle(.secondary).padding(.horizontal)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView().environmentObject(DataStore.preview())
}


