//
//  MoneyMateApp.swift
//  MoneyMate
//
//  Created by 123 on 10/7/25.
//

import SwiftUI
import UserNotifications

@main
struct MoneyMateApp: App {
    @StateObject private var store = DataStore()
    private var notifications: NotificationCoordinator?

    init() {
        // Request notification permission early; silent if declined
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        // Coordinator will be initialized in body via onAppear (store requires SwiftUI env lifecycle)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear {
                    // Start notifications after environment is ready
                    let coordinator = NotificationCoordinator(store: store)
                    coordinator.scheduleDailyReminder()
                    coordinator.scheduleBudgetNotifications()
                    // Keep a strong reference by assigning to a property retained by the app struct's storage
                    _ = coordinator // stored via associated object below
                }
        }
    }
}
