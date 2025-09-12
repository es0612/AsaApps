//
//  EventDetailView.swift
//  AsaEventMap
//  
//  Created on 2025/09/12
//

import SwiftUI
import MapKit

struct EventDetailView: View {
    let event: Event
    @Bindable var viewModel: EventMapViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with Category
                    HStack {
                        ZStack {
                            Circle()
                                .fill(event.category.color.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: event.category.iconName)
                                .foregroundColor(event.category.color)
                                .font(.system(size: 25))
                        }
                        
                        VStack(alignment: .leading) {
                            Text(event.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(event.category.displayName)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(event.category.color.opacity(0.2))
                                .foregroundColor(event.category.color)
                                .cornerRadius(10)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color("AsaSoftCream").opacity(0.3))
                    .cornerRadius(15)
                    
                    // Event Information Cards
                    VStack(spacing: 15) {
                        // Date & Time
                        InfoCard(
                            icon: "calendar",
                            title: "日時",
                            content: event.formattedDate,
                            color: Color("AsaCoffeeBrown")
                        )
                        
                        // Days Until Event
                        if event.isUpcoming {
                            InfoCard(
                                icon: "clock",
                                title: "開催まで",
                                content: "\(event.daysUntilEvent)日後",
                                color: Color("AsaMocha")
                            )
                        }
                        
                        // Location
                        InfoCard(
                            icon: "location",
                            title: "場所",
                            content: event.address.isEmpty ? "場所未設定" : event.address,
                            color: Color("AsaMutedSage")
                        )
                        
                        // Description
                        if !event.eventDescription.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("詳細", systemImage: "text.alignleft")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                Text(event.eventDescription)
                                    .font(.body)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    
                    // Map Preview
                    VStack(alignment: .leading, spacing: 10) {
                        Label("地図", systemImage: "map")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Map(position: .constant(.region(MKCoordinateRegion(
                            center: event.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )))) {
                            Marker(event.title, coordinate: event.coordinate)
                                .tint(event.category.color)
                        }
                        .frame(height: 200)
                        .cornerRadius(15)
                        .onTapGesture {
                            viewModel.centerMapOnEvent(event)
                            dismiss()
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: 15) {
                        // Map Button
                        AsaButton(
                            title: "地図で見る",
                            action: {
                                viewModel.centerMapOnEvent(event)
                                dismiss()
                            },
                            color: Color("AsaCoffeeBrown")
                        )
                        
                        // Delete Button
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("イベント詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("編集") {
                        isEditing = true
                    }
                }
            }
            .alert("イベントを削除", isPresented: $showingDeleteAlert) {
                Button("削除", role: .destructive) {
                    viewModel.deleteEvent(event)
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("このイベントを削除してもよろしいですか？")
            }
            .sheet(isPresented: $isEditing) {
                EditEventView(event: event, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Info Card Component
struct InfoCard: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(content)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    EventDetailView(
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