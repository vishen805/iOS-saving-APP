//
//  NotificationService.swift
//  MoneyMate
//

import Foundation
import UserNotifications
import Combine

final class NotificationCoordinator {
    private let store: DataStore
    private var cancellables: Set<AnyCancellable> = []

    init(store: DataStore) {
        self.store = store
        observeStore()
    }

    private func observeStore() {
        let publishers: [AnyPublisher<Void, Never>] = [
            store.$expenses.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            store.$budgets.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            store.$goals.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            store.$badges.dropFirst().map { _ in () }.eraseToAnyPublisher(),
            store.$challenges.dropFirst().map { _ in () }.eraseToAnyPublisher()
        ]
        Publishers.MergeMany(publishers)
            .debounce(for: .seconds(1.0), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.scheduleBudgetNotifications() }
            .store(in: &cancellables)
    }

    func scheduleBudgetNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["budget-nearing", "budget-exceeded"]) // clear previous

        let nearing = store.nearingLimitCategories()
        if !nearing.isEmpty {
            let names = nearing.map { $0.category.displayName }.joined(separator: ", ")
            let content = UNMutableNotificationContent()
            content.title = "Budget Alert"
            content.body = "Nearing limits: \(names)"
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
            center.add(UNNotificationRequest(identifier: "budget-nearing", content: content, trigger: trigger))
        }

        let exceeded = store.exceededLimitCategories()
        if !exceeded.isEmpty {
            let names = exceeded.map { $0.category.displayName }.joined(separator: ", ")
            let content = UNMutableNotificationContent()
            content.title = "Over Budget"
            content.body = "Exceeded: \(names)"
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2.5, repeats: false)
            center.add(UNNotificationRequest(identifier: "budget-exceeded", content: content, trigger: trigger))
        }
    }

    func scheduleDailyReminder(hour: Int = 9) {
        var date = DateComponents()
        date.hour = hour
        let content = UNMutableNotificationContent()
        content.title = "MoneyMate Reminder"
        content.body = AITips.reminder()
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let req = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}


