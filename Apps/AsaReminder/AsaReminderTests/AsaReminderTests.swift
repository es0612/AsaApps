//
//  AsaReminderTests.swift
//  AsaReminderTests
//  
//  Created on 2025/07/19
//

import Testing
import Foundation
import SwiftData
@testable import AsaReminder

struct AsaReminderTests {
    
    @Test("Reminderモデルの初期化テスト")
    func reminderInitialization() throws {
        let title = "テストリマインダー"
        let content = "テスト用の説明"
        let scheduledDate = Date().addingTimeInterval(3600)
        
        let reminder = Reminder(
            title: title,
            content: content,
            scheduledDate: scheduledDate,
            hasNotification: true
        )
        
        #expect(reminder.title == title)
        #expect(reminder.content == content)
        #expect(reminder.scheduledDate == scheduledDate)
        #expect(reminder.hasNotification == true)
        #expect(reminder.isCompleted == false)
        #expect(reminder.notificationIdentifier != nil)
    }
    
    @Test("期限切れ判定テスト")
    func overdueDetection() throws {
        let pastDate = Date().addingTimeInterval(-3600) // 1時間前
        let futureDate = Date().addingTimeInterval(3600) // 1時間後
        
        let overdueReminder = Reminder(
            title: "期限切れリマインダー",
            scheduledDate: pastDate
        )
        
        let futureReminder = Reminder(
            title: "未来のリマインダー",
            scheduledDate: futureDate
        )
        
        let completedOverdueReminder = Reminder(
            title: "完了済み期限切れリマインダー",
            scheduledDate: pastDate
        )
        completedOverdueReminder.isCompleted = true
        
        #expect(overdueReminder.isOverdue == true)
        #expect(futureReminder.isOverdue == false)
        #expect(completedOverdueReminder.isOverdue == false)
    }
    
    @Test("相対時間表示テスト")
    func timeUntilDueFormatting() throws {
        let futureDate = Date().addingTimeInterval(3600) // 1時間後
        
        let reminder = Reminder(
            title: "テストリマインダー",
            scheduledDate: futureDate
        )
        
        let timeUntilDue = reminder.timeUntilDue
        #expect(!timeUntilDue.isEmpty)
    }
    
    @Test("通知識別子の生成テスト")
    func notificationIdentifierGeneration() throws {
        let reminderWithNotification = Reminder(
            title: "通知ありリマインダー",
            scheduledDate: Date().addingTimeInterval(3600),
            hasNotification: true
        )
        
        let reminderWithoutNotification = Reminder(
            title: "通知なしリマインダー",
            scheduledDate: Date().addingTimeInterval(3600),
            hasNotification: false
        )
        
        #expect(reminderWithNotification.notificationIdentifier != nil)
        #expect(reminderWithoutNotification.notificationIdentifier == nil)
    }
}

struct ReminderViewModelTests {
    
    @Test("ViewModelの初期化テスト")
    func viewModelInitialization() throws {
        let viewModel = ReminderViewModel()
        
        #expect(viewModel.reminders.isEmpty)
        #expect(viewModel.selectedReminder == nil)
        #expect(viewModel.isShowingAddSheet == false)
        #expect(viewModel.isShowingEditSheet == false)
    }
    
    @Test("フィルタリング機能テスト")
    func reminderFiltering() throws {
        let viewModel = ReminderViewModel()
        
        // テスト用のリマインダーを作成
        let pendingReminder = Reminder(title: "予定", scheduledDate: Date().addingTimeInterval(3600))
        let completedReminder = Reminder(title: "完了", scheduledDate: Date().addingTimeInterval(3600))
        completedReminder.isCompleted = true
        let overdueReminder = Reminder(title: "期限切れ", scheduledDate: Date().addingTimeInterval(-3600))
        
        viewModel.reminders = [pendingReminder, completedReminder, overdueReminder]
        
        #expect(viewModel.pendingReminders.count == 1)
        #expect(viewModel.completedReminders.count == 1)
        #expect(viewModel.overdueReminders.count == 1)
        
        #expect(viewModel.pendingReminders.first?.title == "予定")
        #expect(viewModel.completedReminders.first?.title == "完了")
        #expect(viewModel.overdueReminders.first?.title == "期限切れ")
    }
    
    @Test("UI制御機能テスト")
    func uiControlMethods() throws {
        let viewModel = ReminderViewModel()
        let testReminder = Reminder(title: "テスト", scheduledDate: Date())
        
        // Add Sheetの表示/非表示
        viewModel.showAddSheet()
        #expect(viewModel.isShowingAddSheet == true)
        
        viewModel.hideAddSheet()
        #expect(viewModel.isShowingAddSheet == false)
        
        // Edit Sheetの表示/非表示
        viewModel.showEditSheet(for: testReminder)
        #expect(viewModel.isShowingEditSheet == true)
        #expect(viewModel.selectedReminder == testReminder)
        
        viewModel.hideEditSheet()
        #expect(viewModel.isShowingEditSheet == false)
        #expect(viewModel.selectedReminder == nil)
    }
}
