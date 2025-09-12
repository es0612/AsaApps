//
//  EventMapView.swift
//  AsaEventMap
//  
//  Created on 2025/09/12
//

import SwiftUI
import MapKit

struct EventMapView: View {
    @Bindable var viewModel: EventMapViewModel
    @State private var showingFilterSheet = false
    @State private var selectedDetent: PresentationDetent = .medium
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map View
                Map(position: .constant(.region(viewModel.region))) {
                    ForEach(viewModel.filteredEvents) { event in
                        Annotation(event.title, coordinate: event.coordinate) {
                            EventAnnotation(event: event) {
                                viewModel.selectedEvent = event
                                viewModel.isShowingEventDetail = true
                            }
                        }
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                
                // Floating Controls
                VStack {
                    HStack {
                        // Filter Button
                        Button(action: {
                            showingFilterSheet = true
                        }) {
                            HStack {
                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                if viewModel.selectedCategory != nil || !viewModel.searchText.isEmpty {
                                    Text("フィルター中")
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color("AsaSoftCream"))
                            .foregroundColor(Color("AsaDarkSlate"))
                            .cornerRadius(20)
                            .shadow(radius: 3)
                        }
                        
                        Spacer()
                        
                        // Location Buttons
                        VStack(spacing: 10) {
                            // Current Location Button
                            Button(action: {
                                viewModel.centerMapOnCurrentLocation()
                            }) {
                                Image(systemName: "location.fill")
                                    .padding(12)
                                    .background(Color("AsaCoffeeBrown"))
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            
                            // Show All Events Button
                            Button(action: {
                                viewModel.centerMapOnAllEvents()
                            }) {
                                Image(systemName: "map.fill")
                                    .padding(12)
                                    .background(Color("AsaMocha"))
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Add Event Button
                    Button(action: {
                        viewModel.isShowingAddEvent = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("イベントを追加")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("AsaCoffeeBrown"))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("イベントマップ")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingFilterSheet) {
                FilterView(viewModel: viewModel)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $viewModel.isShowingAddEvent) {
                AddEventView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.isShowingEventDetail) {
                if let event = viewModel.selectedEvent {
                    EventDetailView(event: event, viewModel: viewModel)
                        .presentationDetents([.medium, .large], selection: $selectedDetent)
                }
            }
        }
    }
}

// MARK: - Event Annotation Component
struct EventAnnotation: View {
    let event: Event
    let action: () -> Void
    @State private var showingTitle = false
    
    var body: some View {
        VStack(spacing: 0) {
            if showingTitle {
                Text(event.title)
                    .font(.caption)
                    .padding(6)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    .transition(.scale)
            }
            
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(event.category.color)
                        .frame(width: 35, height: 35)
                    
                    Image(systemName: event.category.iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
            }
            
            Image(systemName: "triangle.fill")
                .foregroundColor(event.category.color)
                .font(.system(size: 10))
                .rotationEffect(.degrees(180))
                .offset(y: -3)
        }
        .onTapGesture {
            withAnimation(.spring()) {
                showingTitle.toggle()
            }
        }
    }
}

// MARK: - Filter View
struct FilterView: View {
    @Bindable var viewModel: EventMapViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("イベントを検索", text: $viewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Category Filter
                VStack(alignment: .leading) {
                    Text("カテゴリで絞り込み")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(EventCategory.allCases, id: \.self) { category in
                                CategoryChip(
                                    category: category,
                                    isSelected: viewModel.selectedCategory == category
                                ) {
                                    if viewModel.selectedCategory == category {
                                        viewModel.selectedCategory = nil
                                    } else {
                                        viewModel.selectedCategory = category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Clear Filters Button
                if viewModel.selectedCategory != nil || !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.clearFilters()
                    }) {
                        Text("フィルターをクリア")
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        viewModel.applyFilters()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Category Chip Component
struct CategoryChip: View {
    let category: EventCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: category.iconName)
                Text(category.displayName)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? category.color : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

#Preview {
    EventMapView(viewModel: EventMapViewModel())
}