import SwiftUI

struct AlarmRowView: View {
    @Bindable var alarm: Alarm
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(alarm.timeString)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(alarm.isEnabled ? Color("AsaCoffeeBrown") : Color("AsaMutedSage"))
                
                Text(alarm.label)
                    .font(.headline)
                    .foregroundColor(alarm.isEnabled ? .primary : .secondary)
                    .lineLimit(1)
                
                Text(alarm.repeatText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .toggleStyle(SwitchToggleStyle(tint: Color("AsaCoffeeBrown")))
            .scaleEffect(1.2)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("AsaSoftCream").opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("AsaMutedSage").opacity(0.2), lineWidth: 1)
        )
        .contextMenu {
            Button(action: onDelete) {
                Label("削除", systemImage: "trash")
            }
        }
        .opacity(alarm.isEnabled ? 1.0 : 0.6)
    }
}

#Preview {
    VStack(spacing: 16) {
        AlarmRowView(
            alarm: Alarm(
                time: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date(),
                label: "朝の目覚まし",
                isEnabled: true,
                repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday]
            ),
            onToggle: {},
            onDelete: {}
        )
        
        AlarmRowView(
            alarm: Alarm(
                time: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date(),
                label: "お昼休み",
                isEnabled: false,
                repeatDays: []
            ),
            onToggle: {},
            onDelete: {}
        )
    }
    .padding()
}