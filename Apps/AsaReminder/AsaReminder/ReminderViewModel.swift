//
//  ReminderViewModel.swift
//  AsaReminder
//
//  Created on 2025/07/19
//

import Foundation
import SwiftData
import UserNotifications
import SwiftUI

@Observable
final class ReminderViewModel {
    var reminders: [Reminder] = []
    var selectedReminder: Reminder?
    var isShowingAddSheet = false
    var isShowingEditSheet = false
    var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    
    private var modelContext: ModelContext?
    
    init() {
        requestNotificationPermission()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadReminders()
    }
    
    // MARK: - データ操作
    
    func loadReminders() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<Reminder>(
                sortBy: [SortDescriptor(\.scheduledDate)]
            )
            reminders = try context.fetch(descriptor)
        } catch {
            print("リマインダーの読み込みに失敗しました: \(error)")
        }
    }
    
    func addReminder(title: String, content: String, scheduledDate: Date, hasNotification: Bool) {
        guard let context = modelContext else { return }
        
        let newReminder = Reminder(
            title: title,
            content: content,
            scheduledDate: scheduledDate,
            hasNotification: hasNotification
        )
        
        context.insert(newReminder)
        
        do {
            try context.save()
            loadReminders()
            
            if hasNotification && notificationPermissionStatus == .authorized {
                scheduleNotification(for: newReminder)
            }
        } catch {
            print("リマインダーの保存に失敗しました: \(error)")
        }
    }
    
    func updateReminder(_ reminder: Reminder, title: String, content: String, scheduledDate: Date, hasNotification: Bool) {
        guard let context = modelContext else { return }
        
        // 既存の通知をキャンセル
        if let identifier = reminder.notificationIdentifier {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        }
        
        reminder.title = title
        reminder.content = content
        reminder.scheduledDate = scheduledDate
        reminder.hasNotification = hasNotification
        reminder.updatedAt = Date()
        
        if hasNotification {
            reminder.notificationIdentifier = UUID().uuidString
        } else {
            reminder.notificationIdentifier = nil
        }
        
        do {
            try context.save()
            loadReminders()
            
            if hasNotification && notificationPermissionStatus == .authorized {
                scheduleNotification(for: reminder)
            }
        } catch {
            print("リマインダーの更新に失敗しました: \(error)")
        }
    }
    
    func deleteReminder(_ reminder: Reminder) {
        guard let context = modelContext else { return }
        
        // 通知をキャンセル
        if let identifier = reminder.notificationIdentifier {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        }
        
        context.delete(reminder)
        
        do {
            try context.save()
            loadReminders()
        } catch {
            print("リマインダーの削除に失敗しました: \(error)")
        }
    }
    
    func toggleCompletion(for reminder: Reminder) {
        guard let context = modelContext else { return }
        
        reminder.isCompleted.toggle()
        reminder.updatedAt = Date()
        
        // 完了時は通知をキャンセル
        if reminder.isCompleted, let identifier = reminder.notificationIdentifier {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        }
        
        do {
            try context.save()
            loadReminders()
        } catch {
            print("リマインダーの更新に失敗しました: \(error)")
        }
    }
    
    // MARK: - 通知機能
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.notificationPermissionStatus = granted ? .authorized : .denied
            }
        }
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }
    
    private func scheduleNotification(for reminder: Reminder) {
        guard reminder.hasNotification,
              let identifier = reminder.notificationIdentifier,
              reminder.scheduledDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.content.isEmpty ? "リマインダーの時間です" : reminder.content
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知のスケジュールに失敗しました: \(error)")
            }
        }
    }
    
    // MARK: - UI制御
    
    func showAddSheet() {
        isShowingAddSheet = true
    }
    
    func hideAddSheet() {
        isShowingAddSheet = false
    }
    
    func showEditSheet(for reminder: Reminder) {
        selectedReminder = reminder
        isShowingEditSheet = true
    }
    
    func hideEditSheet() {
        selectedReminder = nil
        isShowingEditSheet = false
    }
    
    // MARK: - フィルタリング
    
    var pendingReminders: [Reminder] {
        reminders.filter { !$0.isCompleted }
    }
    
    var completedReminders: [Reminder] {
        reminders.filter { $0.isCompleted }
    }
    
    var overdueReminders: [Reminder] {
        reminders.filter { $0.isOverdue }
    }
}