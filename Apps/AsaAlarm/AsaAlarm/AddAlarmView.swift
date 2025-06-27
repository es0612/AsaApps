import SwiftUI

struct AddAlarmView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTime = Date()
    @State private var label = ""
    @State private var selectedDays: Set<Weekday> = []
    @State private var soundName = "default"
    
    let onSave: (Alarm) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker("時刻", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                } header: {
                    Text("アラーム時刻")
                }
                
                Section {
                    TextField("アラームの名前", text: $label)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } header: {
                    Text("ラベル")
                }
                
                Section {
                    ForEach(Weekday.allCases, id: \.self) { day in
                        HStack {
                            Text(day.name)
                            Spacer()
                            if selectedDays.contains(day) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleDay(day)
                        }
                    }
                } header: {
                    Text("繰り返し")
                } footer: {
                    Text("選択した曜日に繰り返します。何も選択しない場合は一度のみ鳴ります。")
                }
                
                Section {
                    Picker("音", selection: $soundName) {
                        Text("デフォルト").tag("default")
                        Text("チャイム").tag("chime")
                        Text("ベル").tag("bell")
                        Text("アラーム").tag("alarm")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                } header: {
                    Text("アラーム音")
                }
            }
            .navigationTitle("新しいアラーム")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaMutedSage"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveAlarm()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func toggleDay(_ day: Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
    
    private func saveAlarm() {
        let newAlarm = Alarm(
            time: selectedTime,
            label: label.isEmpty ? "アラーム" : label,
            isEnabled: true,
            repeatDays: selectedDays,
            soundName: soundName
        )
        onSave(newAlarm)
        dismiss()
    }
}

#Preview {
    AddAlarmView { alarm in
        print("アラームが保存されました: \(alarm.timeString)")
    }
}