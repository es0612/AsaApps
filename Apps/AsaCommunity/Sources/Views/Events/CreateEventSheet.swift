import SwiftUI
import AsaUIKit
import AsaCommunityKit

/// イベント作成シート
struct CreateEventSheet: View {
    @Bindable var viewModel: EventCalendarViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var eventDescription = ""
    @State private var location = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var maxParticipants = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("イベント名", text: $title)
                    TextEditor(text: $eventDescription)
                        .frame(minHeight: 80)
                    TextField("場所", text: $location)
                }

                Section("日時") {
                    DatePicker("開始", selection: $startDate)
                    DatePicker("終了", selection: $endDate)
                }

                Section("参加者") {
                    Stepper("定員: \(maxParticipants == 0 ? "制限なし" : "\(maxParticipants)人")", value: $maxParticipants, in: 0...500, step: 5)
                }
            }
            .navigationTitle("イベント作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("作成") {
                        viewModel.createEvent(
                            title: title,
                            description: eventDescription,
                            location: location,
                            latitude: 0,
                            longitude: 0,
                            startDate: startDate,
                            endDate: endDate,
                            maxParticipants: maxParticipants
                        )
                        dismiss()
                    }
                    .disabled(title.isEmpty || location.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
