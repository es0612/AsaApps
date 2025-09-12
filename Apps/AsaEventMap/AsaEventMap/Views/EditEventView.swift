//
//  EditEventView.swift
//  AsaEventMap
//  
//  Created on 2025/09/12
//

import SwiftUI
import MapKit

struct EditEventView: View {
    let event: Event
    @Bindable var viewModel: EventMapViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var eventDescription: String
    @State private var date: Date
    @State private var category: EventCategory
    @State private var address: String
    @State private var coordinate: CLLocationCoordinate2D
    @State private var region: MKCoordinateRegion
    @State private var showingMapPicker = false
    @State private var showingValidationAlert = false
    
    init(event: Event, viewModel: EventMapViewModel) {
        self.event = event
        self.viewModel = viewModel
        
        _title = State(initialValue: event.title)
        _eventDescription = State(initialValue: event.eventDescription)
        _date = State(initialValue: event.date)
        _category = State(initialValue: event.category)
        _address = State(initialValue: event.address)
        _coordinate = State(initialValue: event.coordinate)
        _region = State(initialValue: MKCoordinateRegion(
            center: event.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Information Section
                Section(header: Text("基本情報")) {
                    TextField("イベント名", text: $title)
                    
                    DatePicker("日時", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                    
                    Picker("カテゴリ", selection: $category) {
                        ForEach(EventCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.iconName)
                                Text(category.displayName)
                            }
                            .tag(category)
                        }
                    }
                }
                
                // Description Section
                Section(header: Text("詳細")) {
                    TextField("説明（任意）", text: $eventDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Location Section
                Section(header: Text("場所")) {
                    TextField("住所", text: $address)
                    
                    // Map Preview
                    Map(position: .constant(.region(region))) {
                        Marker("選択位置", coordinate: coordinate)
                            .tint(category.color)
                    }
                    .frame(height: 150)
                    .cornerRadius(10)
                    .onTapGesture {
                        showingMapPicker = true
                    }
                    
                    AsaButton(
                        title: "地図で位置を変更",
                        action: {
                            showingMapPicker = true
                        },
                        color: Color("AsaMocha")
                    )
                }
                
                // Metadata Section
                Section(header: Text("情報")) {
                    HStack {
                        Text("作成日")
                        Spacer()
                        Text(formatDate(event.createdAt))
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("更新日")
                        Spacer()
                        Text(formatDate(event.updatedAt))
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("イベントを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveChanges()
                    }
                    .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showingMapPicker) {
                MapPickerView(coordinate: $coordinate, region: $region, address: $address)
            }
            .alert("入力エラー", isPresented: $showingValidationAlert) {
                Button("OK") {}
            } message: {
                Text("イベント名を入力してください")
            }
        }
    }
    
    // MARK: - Save Changes
    private func saveChanges() {
        guard !title.isEmpty else {
            showingValidationAlert = true
            return
        }
        
        event.title = title
        event.eventDescription = eventDescription
        event.date = date
        event.category = category
        event.latitude = coordinate.latitude
        event.longitude = coordinate.longitude
        event.address = address
        
        viewModel.updateEvent(event)
        dismiss()
    }
    
    // MARK: - Date Formatter
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

#Preview {
    EditEventView(
        event: Event(
            title: "サンプルイベント",
            eventDescription: "これはサンプルイベントの説明です",
            date: Date(),
            category: .meeting,
            latitude: 35.6762,
            longitude: 139.6503,
            address: "東京都千代田区"
        ),
        viewModel: EventMapViewModel()
    )
}