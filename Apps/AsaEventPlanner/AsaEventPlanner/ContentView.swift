//
//  ContentView.swift
//  AsaEventPlanner
//  
//  Created on 2025/08/03
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: EventViewModel
    
    init() {
        let modelContext = ModelContainer.shared.mainContext
        _viewModel = State(initialValue: EventViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                
                if viewModel.filteredEvents.isEmpty {
                    emptyStateView
                } else {
                    eventListView
                }
            }
            .background(Color("AsaDarkSlate").opacity(0.05))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        filterMenu
                    } label: {
                        Image(systemName: "line.horizontal.3.decrease.circle")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.isShowingAddEvent = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "イベントを検索")
            .sheet(isPresented: $viewModel.isShowingAddEvent) {
                AddEventView(viewModel: viewModel)
            }
            .navigationTitle("イベントプランナー")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.loadEvents()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                statisticsCard(
                    title: "総イベント数",
                    value: "\(viewModel.totalEvents)",
                    icon: "calendar.circle.fill",
                    color: Color("AsaCoffeeBrown")
                )
                
                statisticsCard(
                    title: "完了済み",
                    value: "\(viewModel.completedEvents)",
                    icon: "checkmark.circle.fill",
                    color: Color("green")
                )
            }
            
            if !viewModel.upcomingEvents.isEmpty {
                upcomingEventsSection
            }
        }
        .padding()
        .background(Color("AsaSoftCream").opacity(0.3))
    }
    
    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今後の予定")
                .font(.headline)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.upcomingEvents, id: \.id) { event in
                        upcomingEventCard(event: event)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var eventListView: some View {
        List {
            ForEach(viewModel.filteredEvents, id: \.id) { event in
                NavigationLink(destination: EventDetailView(event: event, viewModel: viewModel)) {
                    EventRowView(event: event)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onDelete(perform: deleteEvents)
        }
        .listStyle(PlainListStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(Color("AsaMutedSage"))
            
            Text("イベントがありません")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Text("最初のイベントを作成して\n計画を始めましょう")
                .font(.body)
                .foregroundColor(Color("AsaMutedSage"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            AsaButton(
                title: "イベントを作成",
                action: { viewModel.isShowingAddEvent = true },
                color: Color("AsaCoffeeBrown")
            )
            .padding(.horizontal, 60)
            
            Spacer()
        }
    }
    
    private var filterMenu: some View {
        VStack {
            Button("全て表示") {
                viewModel.filterType = nil
                viewModel.filterStatus = nil
            }
            
            Divider()
            
            Menu("タイプで絞り込み") {
                ForEach(EventType.allCases, id: \.self) { type in
                    Button(type.rawValue) {
                        viewModel.filterType = type
                    }
                }
            }
            
            Menu("ステータスで絞り込み") {
                ForEach(EventStatus.allCases, id: \.self) { status in
                    Button(status.rawValue) {
                        viewModel.filterStatus = status
                    }
                }
            }
        }
    }
    
    private func statisticsCard(title: String, value: String, icon: String, color: Color) -> some View {
        AsaCard {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaDarkSlate"))
                }
                
                Spacer()
            }
        }
    }
    
    private func upcomingEventCard(event: Event) -> some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: event.eventType.iconName)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Spacer()
                    
                    Text("\(event.daysUntilEvent)日")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color("AsaCoffeeBrown"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaDarkSlate"))
                    .lineLimit(2)
                
                Text(event.eventDate, style: .date)
                    .font(.caption)
                    .foregroundColor(Color("AsaMutedSage"))
            }
        }
        .frame(width: 150)
    }
    
    private func deleteEvents(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                viewModel.deleteEvent(viewModel.filteredEvents[index])
            }
        }
    }
}

struct EventRowView: View {
    let event: Event
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: event.eventType.iconName)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        
                        Text(event.title)
                            .font(.headline)
                            .foregroundColor(Color("AsaDarkSlate"))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    statusBadge(status: event.status)
                }
                
                HStack {
                    Label(
                        title: { Text(event.eventDate, style: .date) },
                        icon: { Image(systemName: "calendar") }
                    )
                    .font(.caption)
                    .foregroundColor(Color("AsaMutedSage"))
                    
                    if !event.location.isEmpty {
                        Label(
                            title: { Text(event.location) },
                            icon: { Image(systemName: "location") }
                        )
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                        .lineLimit(1)
                    }
                    
                    Spacer()
                }
                
                if event.totalTasksCount > 0 {
                    progressBar(
                        progress: event.completionProgress,
                        total: event.totalTasksCount,
                        completed: event.completedTasksCount
                    )
                }
                
                HStack {
                    if event.daysUntilEvent >= 0 {
                        Text("あと\(event.daysUntilEvent)日")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(event.daysUntilEvent <= 7 ? Color.red : Color("AsaCoffeeBrown"))
                    } else {
                        Text("\(abs(event.daysUntilEvent))日前")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                        Text("\(event.participants.count)")
                    }
                    .font(.caption)
                    .foregroundColor(Color("AsaMutedSage"))
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func statusBadge(status: EventStatus) -> some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(statusColor(status).opacity(0.2))
            .foregroundColor(statusColor(status))
            .cornerRadius(8)
    }
    
    private func statusColor(_ status: EventStatus) -> Color {
        switch status {
        case .planning: return Color("AsaMutedSage")
        case .inProgress: return Color("AsaCoffeeBrown")
        case .ready: return Color.green
        case .completed: return Color.blue
        case .cancelled: return Color.red
        }
    }
    
    private func progressBar(progress: Double, total: Int, completed: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("準備進捗")
                    .font(.caption)
                    .foregroundColor(Color("AsaMutedSage"))
                
                Spacer()
                
                Text("\(completed)/\(total)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaDarkSlate"))
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color("AsaCoffeeBrown")))
                .scaleEffect(y: 0.5)
        }
    }
}

extension ModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            Event.self,
            EventTask.self,
            Participant.self,
            ShoppingItem.self,
            EventTemplate.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}

// MARK: - Preview Stubs

struct AddEventView: View {
    let viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var eventDate = Date()
    @State private var location = ""
    @State private var eventType: EventType = .other
    @State private var budget: Double = 0
    @State private var isAllDay = true
    @State private var endDate = Date()
    
    @State private var selectedTemplate: EventTemplate?
    @State private var isShowingTemplateSelection = false
    @State private var useTemplate = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // テンプレート選択セクション
                    templateSelectionSection
                    
                    // 基本情報セクション
                    basicInfoSection
                    
                    // 日時設定セクション
                    dateTimeSection
                    
                    // 予算設定セクション
                    budgetSection
                    
                    // 説明セクション
                    descriptionSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("新しいイベント")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("作成") {
                        createEvent()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $isShowingTemplateSelection) {
                TemplateSelectionView(
                    templates: viewModel.templates,
                    selectedTemplate: $selectedTemplate,
                    onTemplateSelected: { template in
                        applyTemplate(template)
                        isShowingTemplateSelection = false
                    }
                )
            }
        }
    }
    
    private var templateSelectionSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("テンプレートを使用")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                }
                
                Toggle("テンプレートから作成", isOn: $useTemplate)
                    .toggleStyle(SwitchToggleStyle(tint: Color("AsaCoffeeBrown")))
                
                if useTemplate {
                    Button(action: {
                        isShowingTemplateSelection = true
                    }) {
                        HStack {
                            Text(selectedTemplate?.name ?? "テンプレートを選択")
                                .foregroundColor(selectedTemplate != nil ? Color("AsaDarkSlate") : Color("AsaMutedSage"))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                        .padding()
                        .background(Color("AsaSoftCream").opacity(0.3))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var basicInfoSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("基本情報")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("イベント名 *")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        TextField("イベント名を入力", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("タイプ")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Picker("イベントタイプ", selection: $eventType) {
                            ForEach(EventType.allCases, id: \.self) { type in
                                HStack {
                                    Image(systemName: type.iconName)
                                    Text(type.rawValue)
                                }
                                .tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color("AsaSoftCream").opacity(0.3))
                        .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("場所")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        TextField("場所を入力（オプション）", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
        }
    }
    
    private var dateTimeSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("日時設定")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    Toggle("終日", isOn: $isAllDay)
                        .toggleStyle(SwitchToggleStyle(tint: Color("AsaCoffeeBrown")))
                    
                    DatePicker(
                        "開始日時",
                        selection: $eventDate,
                        displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    
                    if !isAllDay {
                        DatePicker(
                            "終了日時",
                            selection: $endDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(CompactDatePickerStyle())
                    }
                }
            }
        }
    }
    
    private var budgetSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "yensign.circle")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("予算設定")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("予算額（円）")
                        .font(.subheadline)
                        .foregroundColor(Color("AsaMutedSage"))
                    
                    TextField("0", value: $budget, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    Text("※ 0円の場合は予算管理は行いません")
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                }
            }
        }
    }
    
    private var descriptionSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("詳細説明")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("説明（オプション）")
                        .font(.subheadline)
                        .foregroundColor(Color("AsaMutedSage"))
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color("AsaSoftCream").opacity(0.3))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private func applyTemplate(_ template: EventTemplate) {
        selectedTemplate = template
        eventType = template.eventType
        budget = template.suggestedBudget
        if title.isEmpty {
            title = template.name
        }
        if description.isEmpty {
            description = template.templateDescription
        }
    }
    
    private func createEvent() {
        let event = Event(
            title: title,
            eventDescription: description,
            eventDate: eventDate,
            location: location,
            eventType: eventType,
            budget: budget,
            isAllDay: isAllDay,
            endDate: isAllDay ? nil : endDate
        )
        
        // テンプレートが選択されている場合、デフォルトタスクを追加
        if let template = selectedTemplate {
            for taskTitle in template.defaultTasks {
                let task = EventTask(title: taskTitle)
                event.tasks.append(task)
            }
        }
        
        viewModel.addEvent(event)
        dismiss()
    }
}

struct EventDetailView: View {
    let event: Event
    let viewModel: EventViewModel
    @State private var selectedTab = 0
    @State private var isEditing = false
    
    var body: some View {
        VStack(spacing: 0) {
            eventHeaderView
            
            TabView(selection: $selectedTab) {
                eventOverviewTab
                    .tabItem {
                        Image(systemName: "info.circle")
                        Text("詳細")
                    }
                    .tag(0)
                
                TaskListView(event: event, viewModel: viewModel)
                    .tabItem {
                        Image(systemName: "checklist")
                        Text("タスク")
                    }
                    .tag(1)
                
                ParticipantListView(event: event, viewModel: viewModel)
                    .tabItem {
                        Image(systemName: "person.3")
                        Text("参加者")
                    }
                    .tag(2)
                
                ShoppingListView(event: event, viewModel: viewModel)
                    .tabItem {
                        Image(systemName: "cart")
                        Text("買い物")
                    }
                    .tag(3)
                
                BudgetView(event: event, viewModel: viewModel)
                    .tabItem {
                        Image(systemName: "yensign.circle")
                        Text("予算")
                    }
                    .tag(4)
            }
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("編集") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditEventView(event: event, viewModel: viewModel)
        }
    }
    
    private var eventHeaderView: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: event.eventType.iconName)
                        .font(.title)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        Text(event.eventType.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color("AsaSoftCream"))
                            .foregroundColor(Color("AsaCoffeeBrown"))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if event.daysUntilEvent >= 0 {
                            Text("あと\(event.daysUntilEvent)日")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(event.daysUntilEvent <= 7 ? Color.red : Color("AsaCoffeeBrown"))
                        } else {
                            Text("終了")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                        
                        Text(event.status.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(statusColor(event.status).opacity(0.2))
                            .foregroundColor(statusColor(event.status))
                            .cornerRadius(8)
                    }
                }
                
                HStack {
                    Label(
                        title: { Text(event.eventDate, style: .date) },
                        icon: { Image(systemName: "calendar") }
                    )
                    .font(.subheadline)
                    .foregroundColor(Color("AsaMutedSage"))
                    
                    if !event.location.isEmpty {
                        Label(
                            title: { Text(event.location) },
                            icon: { Image(systemName: "location") }
                        )
                        .font(.subheadline)
                        .foregroundColor(Color("AsaMutedSage"))
                        .lineLimit(1)
                    }
                    
                    Spacer()
                }
                
                if !event.eventDescription.isEmpty {
                    Text(event.eventDescription)
                        .font(.body)
                        .foregroundColor(Color("AsaDarkSlate"))
                        .padding(.top, 4)
                }
                
                // 進捗サマリー
                progressSummaryView
            }
        }
        .padding()
    }
    
    private var progressSummaryView: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("準備進捗")
                    .font(.caption)
                    .foregroundColor(Color("AsaMutedSage"))
                
                HStack(spacing: 4) {
                    Text("\(event.completedTasksCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("/\(event.totalTasksCount)")
                        .font(.title3)
                        .foregroundColor(Color("AsaMutedSage"))
                }
            }
            
            VStack(spacing: 4) {
                Text("参加者")
                    .font(.caption)
                    .foregroundColor(Color("AsaMutedSage"))
                
                Text("\(event.participants.count)人")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AsaCoffeeBrown"))
            }
            
            VStack(spacing: 4) {
                Text("予算")
                    .font(.caption)
                    .foregroundColor(Color("AsaMutedSage"))
                
                if event.budget > 0 {
                    Text("¥\(Int(event.actualSpent))/¥\(Int(event.budget))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(event.actualSpent > event.budget ? Color.red : Color("AsaCoffeeBrown"))
                } else {
                    Text("未設定")
                        .font(.title3)
                        .foregroundColor(Color("AsaMutedSage"))
                }
            }
            
            Spacer()
        }
    }
    
    private var eventOverviewTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !event.eventDescription.isEmpty {
                    AsaCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                Text("イベント詳細")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaDarkSlate"))
                                Spacer()
                            }
                            
                            Text(event.eventDescription)
                                .font(.body)
                                .foregroundColor(Color("AsaDarkSlate"))
                        }
                    }
                }
                
                AsaCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            Text("基本情報")
                                .font(.headline)
                                .foregroundColor(Color("AsaDarkSlate"))
                            Spacer()
                        }
                        
                        infoRow(icon: "calendar", title: "日時", value: formatEventDate())
                        infoRow(icon: "location", title: "場所", value: event.location.isEmpty ? "未設定" : event.location)
                        infoRow(icon: "tag", title: "タイプ", value: event.eventType.rawValue)
                        infoRow(icon: "flag", title: "ステータス", value: event.status.rawValue)
                    }
                }
                
                if event.totalTasksCount > 0 || !event.participants.isEmpty || !event.shoppingItems.isEmpty {
                    AsaCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "chart.bar")
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                Text("進捗サマリー")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaDarkSlate"))
                                Spacer()
                            }
                            
                            if event.totalTasksCount > 0 {
                                progressRow(
                                    title: "タスク完了",
                                    progress: event.completionProgress,
                                    current: event.completedTasksCount,
                                    total: event.totalTasksCount
                                )
                            }
                            
                            if !event.shoppingItems.isEmpty {
                                let purchasedCount = event.shoppingItems.filter { $0.isPurchased }.count
                                progressRow(
                                    title: "買い物完了",
                                    progress: Double(purchasedCount) / Double(event.shoppingItems.count),
                                    current: purchasedCount,
                                    total: event.shoppingItems.count
                                )
                            }
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(Color("AsaMutedSage"))
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color("AsaMutedSage"))
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Spacer()
        }
    }
    
    private func progressRow(title: String, progress: Double, current: Int, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Color("AsaMutedSage"))
                
                Spacer()
                
                Text("\(current)/\(total)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaDarkSlate"))
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color("AsaCoffeeBrown")))
        }
    }
    
    private func statusColor(_ status: EventStatus) -> Color {
        switch status {
        case .planning: return Color("AsaMutedSage")
        case .inProgress: return Color("AsaCoffeeBrown")
        case .ready: return Color.green
        case .completed: return Color.blue
        case .cancelled: return Color.red
        }
    }
    
    private func formatEventDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = event.isAllDay ? .none : .short
        return formatter.string(from: event.eventDate)
    }
}

// MARK: - Stub Views for EventDetailView tabs

struct TaskListView: View {
    let event: Event
    let viewModel: EventViewModel
    
    @State private var isShowingAddTask = false
    @State private var selectedTask: EventTask?
    @State private var isShowingTaskDetail = false
    
    var body: some View {
        VStack(spacing: 0) {
            taskSummaryHeader
            
            if event.tasks.isEmpty {
                emptyTaskState
            } else {
                taskListContent
            }
        }
        .background(Color("AsaDarkSlate").opacity(0.05))
        .sheet(isPresented: $isShowingAddTask) {
            AddTaskView(event: event, viewModel: viewModel)
        }
        .sheet(item: $selectedTask) { task in
            EditTaskView(task: task, viewModel: viewModel)
        }
    }
    
    private var taskSummaryHeader: some View {
        AsaCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "checklist")
                        .font(.title2)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Text("準備タスク")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    Spacer()
                    
                    Button(action: {
                        isShowingAddTask = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
                
                // 進捗表示
                if !event.tasks.isEmpty {
                    progressSection
                }
            }
        }
        .padding()
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("完了状況")
                    .font(.subheadline)
                    .foregroundColor(Color("AsaMutedSage"))
                
                Spacer()
                
                Text("\(event.completedTasksCount)/\(event.totalTasksCount)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AsaDarkSlate"))
            }
            
            ProgressView(value: event.completionProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color("AsaCoffeeBrown")))
                .scaleEffect(y: 1.5)
            
            HStack {
                let percentage = Int(event.completionProgress * 100)
                Text("\(percentage)% 完了")
                    .font(.caption)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Spacer()
                
                if event.completionProgress >= 1.0 {
                    Label("準備完了", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(Color.green)
                } else if event.completionProgress >= 0.5 {
                    Label("順調", systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                } else {
                    Label("準備中", systemImage: "hourglass")
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                }
            }
        }
    }
    
    private var emptyTaskState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "checklist")
                .font(.system(size: 64))
                .foregroundColor(Color("AsaMutedSage"))
            
            Text("タスクがありません")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Text("準備に必要なタスクを\n追加して進捗を管理しましょう")
                .font(.body)
                .foregroundColor(Color("AsaMutedSage"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            AsaButton(
                title: "タスクを追加",
                action: { isShowingAddTask = true },
                color: Color("AsaCoffeeBrown")
            )
            .padding(.horizontal, 60)
            
            Spacer()
        }
    }
    
    private var taskListContent: some View {
        List {
            ForEach(groupedTasks.keys.sorted(by: taskPriorityOrder), id: \.self) { priority in
                Section(header: taskSectionHeader(priority: priority)) {
                    ForEach(groupedTasks[priority] ?? [], id: \.id) { task in
                        TaskRowView(
                            task: task,
                            onToggle: {
                                viewModel.toggleTaskCompletion(task)
                            },
                            onEdit: {
                                selectedTask = task
                            }
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { indexSet in
                        deleteTasksInPriority(priority: priority, offsets: indexSet)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var groupedTasks: [TaskPriority: [EventTask]] {
        Dictionary(grouping: event.tasks) { $0.priority }
    }
    
    private func taskPriorityOrder(_ lhs: TaskPriority, _ rhs: TaskPriority) -> Bool {
        let order: [TaskPriority] = [.urgent, .high, .medium, .low]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
    
    private func taskSectionHeader(priority: TaskPriority) -> some View {
        HStack {
            Image(systemName: priority.iconName)
                .foregroundColor(Color(priority.color))
            
            Text(priority.rawValue + "優先度")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Spacer()
            
            let count = groupedTasks[priority]?.count ?? 0
            Text("\(count)件")
                .font(.caption)
                .foregroundColor(Color("AsaMutedSage"))
        }
        .padding(.vertical, 4)
    }
    
    private func deleteTasksInPriority(priority: TaskPriority, offsets: IndexSet) {
        guard let tasks = groupedTasks[priority] else { return }
        for index in offsets {
            viewModel.deleteTask(tasks[index])
        }
    }
}

struct TaskRowView: View {
    let task: EventTask
    let onToggle: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        AsaCard {
            HStack(spacing: 12) {
                // 完了チェックボックス
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(task.isCompleted ? Color.green : Color("AsaMutedSage"))
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(task.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(task.isCompleted ? Color("AsaMutedSage") : Color("AsaDarkSlate"))
                            .strikethrough(task.isCompleted)
                        
                        Spacer()
                        
                        priorityBadge(priority: task.priority)
                    }
                    
                    if !task.taskDescription.isEmpty {
                        Text(task.taskDescription)
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                            .lineLimit(2)
                    }
                    
                    HStack {
                        if let dueDate = task.dueDate {
                            Label(
                                title: { Text(dueDate, style: .date) },
                                icon: { Image(systemName: "calendar") }
                            )
                            .font(.caption)
                            .foregroundColor(task.isOverdue ? Color.red : Color("AsaMutedSage"))
                            
                            if task.isOverdue && !task.isCompleted {
                                Text("期限切れ")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.red)
                            }
                        }
                        
                        Spacer()
                        
                        if task.isCompleted, let completedAt = task.completedAt {
                            Text("完了: \(completedAt, style: .date)")
                                .font(.caption)
                                .foregroundColor(Color.green)
                        }
                    }
                }
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.subheadline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .opacity(task.isCompleted ? 0.7 : 1.0)
        .padding(.vertical, 2)
    }
    
    private func priorityBadge(priority: TaskPriority) -> some View {
        Text(priority.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(priority.color).opacity(0.2))
            .foregroundColor(Color(priority.color))
            .cornerRadius(4)
    }
}

struct ParticipantListView: View {
    let event: Event
    let viewModel: EventViewModel
    
    @State private var isShowingAddParticipant = false
    @State private var selectedParticipant: Participant?
    
    var body: some View {
        VStack(spacing: 0) {
            participantSummaryHeader
            
            if event.participants.isEmpty {
                emptyParticipantState
            } else {
                participantListContent
            }
        }
        .background(Color("AsaDarkSlate").opacity(0.05))
        .sheet(isPresented: $isShowingAddParticipant) {
            AddParticipantView(event: event, viewModel: viewModel)
        }
        .sheet(item: $selectedParticipant) { participant in
            EditParticipantView(participant: participant, viewModel: viewModel)
        }
    }
    
    private var participantSummaryHeader: some View {
        AsaCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.title2)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Text("参加者管理")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    Spacer()
                    
                    Button(action: {
                        isShowingAddParticipant = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
                
                if !event.participants.isEmpty {
                    participantStatsSection
                }
            }
        }
        .padding()
    }
    
    private var participantStatsSection: some View {
        VStack(spacing: 8) {
            HStack {
                participantStatCard(
                    title: "総参加者",
                    count: event.participants.count,
                    color: Color("AsaCoffeeBrown")
                )
                
                participantStatCard(
                    title: "参加確定",
                    count: event.participants.filter { $0.status == .confirmed }.count,
                    color: Color.green
                )
                
                participantStatCard(
                    title: "返答待ち",
                    count: event.participants.filter { $0.status == .pending }.count,
                    color: Color.orange
                )
            }
        }
    }
    
    private func participantStatCard(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color("AsaMutedSage"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var emptyParticipantState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.3")
                .font(.system(size: 64))
                .foregroundColor(Color("AsaMutedSage"))
            
            Text("参加者がいません")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Text("イベントの参加者を追加して\n連絡先や参加状況を管理しましょう")
                .font(.body)
                .foregroundColor(Color("AsaMutedSage"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            AsaButton(
                title: "参加者を追加",
                action: { isShowingAddParticipant = true },
                color: Color("AsaCoffeeBrown")
            )
            .padding(.horizontal, 60)
            
            Spacer()
        }
    }
    
    private var participantListContent: some View {
        List {
            ForEach(groupedParticipants.keys.sorted(by: statusOrder), id: \.self) { status in
                Section(header: participantSectionHeader(status: status)) {
                    ForEach(groupedParticipants[status] ?? [], id: \.id) { participant in
                        ParticipantRowView(
                            participant: participant,
                            onStatusUpdate: { newStatus in
                                viewModel.updateParticipantStatus(participant, status: newStatus)
                            },
                            onEdit: {
                                selectedParticipant = participant
                            }
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { indexSet in
                        deleteParticipantsInStatus(status: status, offsets: indexSet)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var groupedParticipants: [ParticipantStatus: [Participant]] {
        Dictionary(grouping: event.participants) { $0.status }
    }
    
    private func statusOrder(_ lhs: ParticipantStatus, _ rhs: ParticipantStatus) -> Bool {
        let order: [ParticipantStatus] = [.confirmed, .pending, .maybe, .invited, .declined]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
    
    private func participantSectionHeader(status: ParticipantStatus) -> some View {
        HStack {
            Image(systemName: status.iconName)
                .foregroundColor(Color(status.color))
            
            Text(status.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Spacer()
            
            let count = groupedParticipants[status]?.count ?? 0
            Text("\(count)人")
                .font(.caption)
                .foregroundColor(Color("AsaMutedSage"))
        }
        .padding(.vertical, 4)
    }
    
    private func deleteParticipantsInStatus(status: ParticipantStatus, offsets: IndexSet) {
        guard let participants = groupedParticipants[status] else { return }
        for index in offsets {
            viewModel.deleteParticipant(participants[index])
        }
    }
}

struct ParticipantRowView: View {
    let participant: Participant
    let onStatusUpdate: (ParticipantStatus) -> Void
    let onEdit: () -> Void
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(participant.displayInfo)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        if participant.hasContactInfo {
                            VStack(alignment: .leading, spacing: 2) {
                                if !participant.email.isEmpty {
                                    Label(
                                        title: { Text(participant.email) },
                                        icon: { Image(systemName: "envelope") }
                                    )
                                    .font(.caption)
                                    .foregroundColor(Color("AsaMutedSage"))
                                }
                                
                                if !participant.phone.isEmpty {
                                    Label(
                                        title: { Text(participant.phone) },
                                        icon: { Image(systemName: "phone") }
                                    )
                                    .font(.caption)
                                    .foregroundColor(Color("AsaMutedSage"))
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        statusBadge(status: participant.status)
                        
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.subheadline)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // 参加状況変更ボタン
                if participant.status != .confirmed {
                    statusChangeButtons
                }
                
                if !participant.notes.isEmpty {
                    Text(participant.notes)
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                        .padding(.top, 4)
                        .italic()
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private var statusChangeButtons: some View {
        HStack(spacing: 8) {
            if participant.status != .confirmed {
                Button("参加確定") {
                    onStatusUpdate(.confirmed)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .foregroundColor(Color.green)
                .cornerRadius(6)
            }
            
            if participant.status != .declined {
                Button("欠席") {
                    onStatusUpdate(.declined)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.2))
                .foregroundColor(Color.red)
                .cornerRadius(6)
            }
            
            if participant.status != .pending {
                Button("返答待ち") {
                    onStatusUpdate(.pending)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .foregroundColor(Color.orange)
                .cornerRadius(6)
            }
            
            Spacer()
        }
    }
    
    private func statusBadge(status: ParticipantStatus) -> some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(status.color).opacity(0.2))
            .foregroundColor(Color(status.color))
            .cornerRadius(4)
    }
}

struct ShoppingListView: View {
    let event: Event
    let viewModel: EventViewModel
    
    @State private var isShowingAddItem = false
    @State private var selectedItem: ShoppingItem?
    @State private var isShowingItemDetail = false
    
    var body: some View {
        VStack(spacing: 0) {
            shoppingSummaryHeader
            
            if event.shoppingItems.isEmpty {
                emptyShoppingState
            } else {
                shoppingListContent
            }
        }
        .background(Color("AsaDarkSlate").opacity(0.05))
        .sheet(isPresented: $isShowingAddItem) {
            AddShoppingItemView(event: event, viewModel: viewModel)
        }
        .sheet(item: $selectedItem) { item in
            EditShoppingItemView(item: item, viewModel: viewModel)
        }
    }
    
    private var shoppingSummaryHeader: some View {
        AsaCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "cart.fill")
                        .font(.title2)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Text("買い物リスト")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    Spacer()
                    
                    Button(action: {
                        isShowingAddItem = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
                
                if !event.shoppingItems.isEmpty {
                    shoppingSummaryStats
                }
            }
        }
        .padding()
    }
    
    private var shoppingSummaryStats: some View {
        VStack(spacing: 12) {
            HStack {
                statCard(
                    title: "総アイテム",
                    value: "\(event.shoppingItems.count)",
                    color: Color("AsaCoffeeBrown")
                )
                
                statCard(
                    title: "購入済み",
                    value: "\(purchasedItemsCount)",
                    color: Color.green
                )
                
                statCard(
                    title: "予算",
                    value: "¥\(Int(totalEstimatedCost))",
                    color: Color("AsaMutedSage")
                )
                
                statCard(
                    title: "実際",
                    value: "¥\(Int(totalActualCost))",
                    color: totalActualCost > totalEstimatedCost ? Color.red : Color("AsaCoffeeBrown")
                )
            }
            
            // 購入進捗バー
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("購入進捗")
                        .font(.subheadline)
                        .foregroundColor(Color("AsaMutedSage"))
                    
                    Spacer()
                    
                    Text("\(purchasedItemsCount)/\(event.shoppingItems.count)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaDarkSlate"))
                }
                
                ProgressView(value: purchaseProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color("AsaCoffeeBrown")))
                    .scaleEffect(y: 1.5)
                
                HStack {
                    let percentage = Int(purchaseProgress * 100)
                    Text("\(percentage)% 完了")
                        .font(.caption)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Spacer()
                    
                    if purchaseProgress >= 1.0 {
                        Label("全て購入済み", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color.green)
                    }
                }
            }
        }
    }
    
    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color("AsaMutedSage"))
        }
        .frame(maxWidth: .infinity)
    }
    
    private var emptyShoppingState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "cart")
                .font(.system(size: 64))
                .foregroundColor(Color("AsaMutedSage"))
            
            Text("買い物リストが空です")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Text("イベントに必要なアイテムを\n追加して買い物を管理しましょう")
                .font(.body)
                .foregroundColor(Color("AsaMutedSage"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            AsaButton(
                title: "アイテムを追加",
                action: { isShowingAddItem = true },
                color: Color("AsaCoffeeBrown")
            )
            .padding(.horizontal, 60)
            
            Spacer()
        }
    }
    
    private var shoppingListContent: some View {
        List {
            ForEach(groupedShoppingItems.keys.sorted(by: categoryOrder), id: \.self) { category in
                Section(header: categorySectionHeader(category: category)) {
                    ForEach(groupedShoppingItems[category] ?? [], id: \.id) { item in
                        ShoppingItemRowView(
                            item: item,
                            onTogglePurchased: {
                                if item.isPurchased {
                                    viewModel.toggleItemPurchased(item)
                                } else {
                                    // 購入時は価格を確認
                                    showPurchaseConfirmation(for: item)
                                }
                            },
                            onEdit: {
                                selectedItem = item
                            }
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { indexSet in
                        deleteItemsInCategory(category: category, offsets: indexSet)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var groupedShoppingItems: [ShoppingCategory: [ShoppingItem]] {
        Dictionary(grouping: event.shoppingItems) { $0.category }
    }
    
    private func categoryOrder(_ lhs: ShoppingCategory, _ rhs: ShoppingCategory) -> Bool {
        let order: [ShoppingCategory] = [.food, .drinks, .decoration, .supplies, .gift, .stationery, .clothing, .electronics, .other]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
    
    private func categorySectionHeader(category: ShoppingCategory) -> some View {
        HStack {
            Image(systemName: category.iconName)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Spacer()
            
            let count = groupedShoppingItems[category]?.count ?? 0
            Text("\(count)件")
                .font(.caption)
                .foregroundColor(Color("AsaMutedSage"))
        }
        .padding(.vertical, 4)
    }
    
    private func deleteItemsInCategory(category: ShoppingCategory, offsets: IndexSet) {
        guard let items = groupedShoppingItems[category] else { return }
        for index in offsets {
            viewModel.deleteShoppingItem(items[index])
        }
    }
    
    private func showPurchaseConfirmation(for item: ShoppingItem) {
        // 実際の価格入力なしで購入マーク
        viewModel.toggleItemPurchased(item)
    }
    
    // MARK: - Computed Properties
    
    private var purchasedItemsCount: Int {
        event.shoppingItems.filter { $0.isPurchased }.count
    }
    
    private var totalEstimatedCost: Double {
        event.shoppingItems.reduce(0) { $0 + $1.totalEstimatedCost }
    }
    
    private var totalActualCost: Double {
        event.shoppingItems.filter { $0.isPurchased }.reduce(0) { $0 + $1.totalActualCost }
    }
    
    private var purchaseProgress: Double {
        guard !event.shoppingItems.isEmpty else { return 0.0 }
        return Double(purchasedItemsCount) / Double(event.shoppingItems.count)
    }
}

struct ShoppingItemRowView: View {
    let item: ShoppingItem
    let onTogglePurchased: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // 購入チェックボックス
                    Button(action: onTogglePurchased) {
                        Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(item.isPurchased ? Color.green : Color("AsaMutedSage"))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(item.isPurchased ? Color("AsaMutedSage") : Color("AsaDarkSlate"))
                                .strikethrough(item.isPurchased)
                            
                            Spacer()
                            
                            categoryBadge(category: item.category)
                        }
                        
                        if !item.itemDescription.isEmpty {
                            Text(item.itemDescription)
                                .font(.caption)
                                .foregroundColor(Color("AsaMutedSage"))
                                .lineLimit(2)
                        }
                        
                        HStack {
                            // 価格表示
                            Text(item.priceDisplay)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(priceColor)
                            
                            if !item.store.isEmpty {
                                Label(
                                    title: { Text(item.store) },
                                    icon: { Image(systemName: "storefront") }
                                )
                                .font(.caption)
                                .foregroundColor(Color("AsaMutedSage"))
                            }
                            
                            Spacer()
                            
                            if item.isPurchased, let purchasedAt = item.purchasedAt {
                                Text("購入済み: \(purchasedAt, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(Color.green)
                            }
                        }
                        
                        if !item.notes.isEmpty {
                            Text(item.notes)
                                .font(.caption)
                                .foregroundColor(Color("AsaMutedSage"))
                                .italic()
                                .padding(.top, 4)
                        }
                    }
                    
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .opacity(item.isPurchased ? 0.7 : 1.0)
        .padding(.vertical, 2)
    }
    
    private func categoryBadge(category: ShoppingCategory) -> some View {
        HStack(spacing: 4) {
            Image(systemName: category.iconName)
                .font(.caption)
            Text(category.rawValue)
                .font(.caption)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color("AsaSoftCream"))
        .foregroundColor(Color("AsaCoffeeBrown"))
        .cornerRadius(4)
    }
    
    private var priceColor: Color {
        if item.isPurchased {
            return item.actualPrice > item.estimatedPrice ? Color.red : Color.green
        } else {
            return Color("AsaCoffeeBrown")
        }
    }
}

struct BudgetView: View {
    let event: Event
    let viewModel: EventViewModel
    
    @State private var isShowingBudgetAdjustment = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                budgetOverviewCard
                
                spendingBreakdownCard
                
                categorySpendingCard
                
                budgetRecommendationsCard
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .background(Color("AsaDarkSlate").opacity(0.05))
        .sheet(isPresented: $isShowingBudgetAdjustment) {
            BudgetAdjustmentView(event: event, viewModel: viewModel)
        }
    }
    
    private var budgetOverviewCard: some View {
        AsaCard {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .font(.title2)
                    
                    Text("予算概要")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    Spacer()
                    
                    Button(action: {
                        isShowingBudgetAdjustment = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
                
                VStack(spacing: 16) {
                    // 予算サマリー
                    HStack {
                        budgetStatCard(
                            title: "予算",
                            amount: event.budget,
                            color: Color("AsaCoffeeBrown"),
                            subtitle: "設定予算"
                        )
                        
                        budgetStatCard(
                            title: "実際",
                            amount: event.actualSpent,
                            color: budgetStatusColor,
                            subtitle: "支出済み"
                        )
                        
                        budgetStatCard(
                            title: "残額",
                            amount: remainingBudget,
                            color: remainingBudget >= 0 ? Color.green : Color.red,
                            subtitle: remainingBudget >= 0 ? "利用可能" : "予算超過"
                        )
                    }
                    
                    // 予算進捗バー
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("予算使用率")
                                .font(.subheadline)
                                .foregroundColor(Color("AsaMutedSage"))
                            
                            Spacer()
                            
                            Text("\(budgetUsagePercentage)%")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(budgetStatusColor)
                        }
                        
                        ProgressView(value: min(budgetUsageProgress, 1.0))
                            .progressViewStyle(LinearProgressViewStyle(tint: budgetStatusColor))
                            .scaleEffect(y: 2.0)
                        
                        if budgetUsageProgress > 1.0 {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color.red)
                                Text("予算を\(Int((budgetUsageProgress - 1.0) * 100))%超過しています")
                                    .font(.caption)
                                    .foregroundColor(Color.red)
                            }
                        } else if budgetUsageProgress > 0.8 {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(Color.orange)
                                Text("予算の80%以上を使用しています")
                                    .font(.caption)
                                    .foregroundColor(Color.orange)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var spendingBreakdownCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .font(.title2)
                    
                    Text("支出内訳")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    Spacer()
                }
                
                if purchasedItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "cart")
                            .font(.largeTitle)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Text("まだ購入アイテムがありません")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Text("買い物リストでアイテムを購入済みにマークすると、ここに支出内訳が表示されます。")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(purchasedItems.prefix(5), id: \.id) { item in
                            SpendingItemRow(item: item)
                        }
                        
                        if purchasedItems.count > 5 {
                            Button(action: {
                                // 全支出を表示
                            }) {
                                Text("他\(purchasedItems.count - 5)件を表示...")
                                    .font(.caption)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var categorySpendingCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "square.grid.3x3.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .font(.title2)
                    
                    Text("カテゴリ別支出")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    Spacer()
                }
                
                if categorySpending.isEmpty {
                    Text("カテゴリ別の支出データがありません")
                        .font(.subheadline)
                        .foregroundColor(Color("AsaMutedSage"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(categorySpending.sorted(by: { $0.value > $1.value }), id: \.key) { category, amount in
                            CategorySpendingRow(
                                category: category,
                                amount: amount,
                                totalSpent: event.actualSpent
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var budgetRecommendationsCard: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                        .font(.title2)
                    
                    Text("予算アドバイス")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    Spacer()
                }
                
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(budgetRecommendations, id: \.self) { recommendation in
                        BudgetRecommendationRow(recommendation: recommendation)
                    }
                }
            }
        }
    }
    
    private func budgetStatCard(title: String, amount: Double, color: Color, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Text("¥\(Int(amount))")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(Color("AsaMutedSage"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color("AsaSoftCream").opacity(0.3))
        .cornerRadius(8)
    }
    
    // MARK: - Computed Properties
    
    private var purchasedItems: [ShoppingItem] {
        event.shoppingItems.filter { $0.isPurchased }
    }
    
    private var remainingBudget: Double {
        event.budget - event.actualSpent
    }
    
    private var budgetUsageProgress: Double {
        guard event.budget > 0 else { return 0.0 }
        return event.actualSpent / event.budget
    }
    
    private var budgetUsagePercentage: Int {
        Int(budgetUsageProgress * 100)
    }
    
    private var budgetStatusColor: Color {
        if budgetUsageProgress > 1.0 {
            return Color.red
        } else if budgetUsageProgress > 0.8 {
            return Color.orange
        } else {
            return Color.green
        }
    }
    
    private var categorySpending: [ShoppingCategory: Double] {
        var spending: [ShoppingCategory: Double] = [:]
        for item in purchasedItems {
            spending[item.category, default: 0.0] += item.totalActualCost
        }
        return spending
    }
    
    private var budgetRecommendations: [BudgetRecommendation] {
        var recommendations: [BudgetRecommendation] = []
        
        // 予算超過の警告
        if budgetUsageProgress > 1.0 {
            recommendations.append(.overBudget(amount: event.actualSpent - event.budget))
        }
        
        // 予算不足の警告
        else if budgetUsageProgress > 0.8 {
            recommendations.append(.nearBudgetLimit(remaining: remainingBudget))
        }
        
        // カテゴリ別の支出警告
        let highSpendingCategory = categorySpending.max(by: { $0.value < $1.value })
        if let (category, amount) = highSpendingCategory, amount > event.budget * 0.4 {
            recommendations.append(.highCategorySpending(category: category, amount: amount))
        }
        
        // 未購入アイテムの予算警告
        let unpurchasedTotal = event.shoppingItems.filter { !$0.isPurchased }.reduce(0) { $0 + $1.totalEstimatedCost }
        if unpurchasedTotal > remainingBudget && remainingBudget > 0 {
            recommendations.append(.insufficientBudgetForPlanned(needed: unpurchasedTotal, available: remainingBudget))
        }
        
        // 良好な予算管理のお祝い
        if budgetUsageProgress <= 0.8 && !purchasedItems.isEmpty {
            recommendations.append(.goodBudgetManagement)
        }
        
        return recommendations
    }
}

struct SpendingItemRow: View {
    let item: ShoppingItem
    
    var body: some View {
        HStack {
            Image(systemName: item.category.iconName)
                .foregroundColor(Color("AsaCoffeeBrown"))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.subheadline)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text(item.category.rawValue)
                    .font(.caption)
                    .foregroundColor(Color("AsaMutedSage"))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("¥\(Int(item.totalActualCost))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                if item.actualPrice != item.estimatedPrice {
                    let difference = item.totalActualCost - item.totalEstimatedCost
                    Text("\(difference > 0 ? "+" : "")¥\(Int(difference))")
                        .font(.caption)
                        .foregroundColor(difference > 0 ? Color.red : Color.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct CategorySpendingRow: View {
    let category: ShoppingCategory
    let amount: Double
    let totalSpent: Double
    
    private var percentage: Double {
        guard totalSpent > 0 else { return 0.0 }
        return amount / totalSpent
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: category.iconName)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .frame(width: 20)
                
                Text(category.rawValue)
                    .font(.subheadline)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("¥\(Int(amount))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    Text("\(Int(percentage * 100))%")
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                }
            }
            
            ProgressView(value: percentage)
                .progressViewStyle(LinearProgressViewStyle(tint: Color("AsaCoffeeBrown")))
                .scaleEffect(y: 1.5)
        }
    }
}

enum BudgetRecommendation: Hashable {
    case overBudget(amount: Double)
    case nearBudgetLimit(remaining: Double)
    case highCategorySpending(category: ShoppingCategory, amount: Double)
    case insufficientBudgetForPlanned(needed: Double, available: Double)
    case goodBudgetManagement
    
    var icon: String {
        switch self {
        case .overBudget: return "exclamationmark.triangle.fill"
        case .nearBudgetLimit: return "exclamationmark.circle.fill"
        case .highCategorySpending: return "chart.bar.fill"
        case .insufficientBudgetForPlanned: return "calendar.badge.exclamationmark"
        case .goodBudgetManagement: return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .overBudget: return Color.red
        case .nearBudgetLimit: return Color.orange
        case .highCategorySpending: return Color.orange
        case .insufficientBudgetForPlanned: return Color.red
        case .goodBudgetManagement: return Color.green
        }
    }
    
    var message: String {
        switch self {
        case .overBudget(let amount):
            return "予算を¥\(Int(amount))超過しています。支出の見直しを検討してください。"
        case .nearBudgetLimit(let remaining):
            return "残り予算は¥\(Int(remaining))です。今後の購入にご注意ください。"
        case .highCategorySpending(let category, let amount):
            return "\(category.rawValue)で¥\(Int(amount))と多く支出しています。"
        case .insufficientBudgetForPlanned(let needed, let available):
            return "予定アイテムに¥\(Int(needed))必要ですが、残り予算は¥\(Int(available))です。"
        case .goodBudgetManagement:
            return "予算内で順調に管理できています！この調子で続けましょう。"
        }
    }
}

struct BudgetRecommendationRow: View {
    let recommendation: BudgetRecommendation
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: recommendation.icon)
                .foregroundColor(recommendation.color)
                .frame(width: 20)
                .padding(.top, 2)
            
            Text(recommendation.message)
                .font(.subheadline)
                .foregroundColor(Color("AsaDarkSlate"))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct BudgetAdjustmentView: View {
    let event: Event
    let viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var newBudget: Double
    
    init(event: Event, viewModel: EventViewModel) {
        self.event = event
        self.viewModel = viewModel
        self._newBudget = State(initialValue: event.budget)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                AsaCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            Text("予算調整")
                                .font(.headline)
                                .foregroundColor(Color("AsaDarkSlate"))
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("現在の予算: ¥\(Int(event.budget))")
                                .font(.subheadline)
                                .foregroundColor(Color("AsaMutedSage"))
                            
                            Text("現在の支出: ¥\(Int(event.actualSpent))")
                                .font(.subheadline)
                                .foregroundColor(Color("AsaMutedSage"))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("新しい予算")
                                    .font(.subheadline)
                                    .foregroundColor(Color("AsaMutedSage"))
                                
                                TextField("予算額", value: $newBudget, format: .number)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }
                            
                            if newBudget != event.budget {
                                let difference = newBudget - event.budget
                                Text("変更: \(difference > 0 ? "+" : "")¥\(Int(difference))")
                                    .font(.caption)
                                    .foregroundColor(difference > 0 ? Color.green : Color.red)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("予算調整")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        event.budget = newBudget
                        viewModel.updateEvent(event)
                        dismiss()
                    }
                    .disabled(newBudget == event.budget || newBudget < 0)
                }
            }
        }
    }
}

struct EditEventView: View {
    let event: Event
    let viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var eventDescription: String
    @State private var location: String
    @State private var eventDate: Date
    @State private var endDate: Date?
    @State private var eventType: EventType
    @State private var status: EventStatus
    @State private var budget: Double
    @State private var isAllDay: Bool
    @State private var hasEndDate: Bool
    
    @State private var showingDeleteConfirmation = false
    
    init(event: Event, viewModel: EventViewModel) {
        self.event = event
        self.viewModel = viewModel
        
        _title = State(initialValue: event.title)
        _eventDescription = State(initialValue: event.eventDescription)
        _location = State(initialValue: event.location)
        _eventDate = State(initialValue: event.eventDate)
        _endDate = State(initialValue: event.endDate)
        _eventType = State(initialValue: event.eventType)
        _status = State(initialValue: event.status)
        _budget = State(initialValue: event.budget)
        _isAllDay = State(initialValue: event.isAllDay)
        _hasEndDate = State(initialValue: event.endDate != nil)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    basicInformationSection
                    
                    dateAndTimeSection
                    
                    eventDetailsSection
                    
                    budgetSection
                    
                    statusSection
                    
                    dangerZoneSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .background(Color("AsaDarkSlate").opacity(0.05))
            .navigationTitle("イベント編集")
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
                    .disabled(title.isEmpty)
                }
            }
            .alert("イベントを削除", isPresented: $showingDeleteConfirmation) {
                Button("削除", role: .destructive) {
                    deleteEvent()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("この操作は取り消せません。イベントに関連するすべてのデータが削除されます。")
            }
        }
    }
    
    private var basicInformationSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("基本情報")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("イベント名 *")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        TextField("イベント名を入力", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("説明")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        TextEditor(text: $eventDescription)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color("AsaSoftCream").opacity(0.3))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("場所")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        TextField("場所を入力", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
        }
    }
    
    private var dateAndTimeSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("日時設定")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("開始日時")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        DatePicker(
                            "開始日時",
                            selection: $eventDate,
                            displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
                        )
                        .datePickerStyle(CompactDatePickerStyle())
                    }
                    
                    Toggle("終日", isOn: $isAllDay)
                        .toggleStyle(SwitchToggleStyle(tint: Color("AsaCoffeeBrown")))
                    
                    Toggle("終了日時を設定", isOn: $hasEndDate)
                        .toggleStyle(SwitchToggleStyle(tint: Color("AsaCoffeeBrown")))
                        .onChange(of: hasEndDate) { _, newValue in
                            if newValue && endDate == nil {
                                endDate = Calendar.current.date(byAdding: .hour, value: 2, to: eventDate) ?? eventDate
                            } else if !newValue {
                                endDate = nil
                            }
                        }
                    
                    if hasEndDate {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("終了日時")
                                .font(.subheadline)
                                .foregroundColor(Color("AsaMutedSage"))
                            
                            DatePicker(
                                "終了日時",
                                selection: Binding(
                                    get: { endDate ?? eventDate },
                                    set: { endDate = $0 }
                                ),
                                displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
                            )
                            .datePickerStyle(CompactDatePickerStyle())
                        }
                    }
                }
            }
        }
    }
    
    private var eventDetailsSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "tag")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("イベント詳細")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("イベントタイプ")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Picker("イベントタイプ", selection: $eventType) {
                            ForEach(EventType.allCases, id: \.self) { type in
                                HStack {
                                    Image(systemName: type.iconName)
                                    Text(type.rawValue)
                                }
                                .tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color("AsaSoftCream").opacity(0.3))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var budgetSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "yensign.circle")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("予算設定")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("予算額（円）")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        TextField("0", value: $budget, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    if budget != event.budget {
                        let difference = budget - event.budget
                        HStack {
                            Text("変更:")
                                .font(.caption)
                                .foregroundColor(Color("AsaMutedSage"))
                            
                            Text("\(difference > 0 ? "+" : "")¥\(Int(difference))")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(difference > 0 ? Color.green : Color.red)
                        }
                    }
                    
                    if event.actualSpent > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("現在の支出: ¥\(Int(event.actualSpent))")
                                .font(.caption)
                                .foregroundColor(Color("AsaMutedSage"))
                            
                            if budget > 0 {
                                let usage = event.actualSpent / budget
                                Text("予算使用率: \(Int(usage * 100))%")
                                    .font(.caption)
                                    .foregroundColor(usage > 1.0 ? Color.red : usage > 0.8 ? Color.orange : Color.green)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var statusSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "flag")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("ステータス")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("イベントステータス")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Picker("ステータス", selection: $status) {
                            ForEach(EventStatus.allCases, id: \.self) { eventStatus in
                                Text(eventStatus.rawValue)
                                    .tag(eventStatus)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    if status != event.status {
                        HStack {
                            Text("変更:")
                                .font(.caption)
                                .foregroundColor(Color("AsaMutedSage"))
                            
                            Text("\(event.status.rawValue) → \(status.rawValue)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                    }
                }
            }
        }
    }
    
    private var dangerZoneSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(Color.red)
                    Text("危険な操作")
                        .font(.headline)
                        .foregroundColor(Color.red)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("イベントを削除すると、関連するすべてのタスク、参加者、買い物リストなどのデータも完全に削除されます。この操作は取り消せません。")
                        .font(.subheadline)
                        .foregroundColor(Color("AsaMutedSage"))
                        .lineSpacing(2)
                    
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("イベントを削除")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        event.title = title
        event.eventDescription = eventDescription
        event.location = location
        event.eventDate = eventDate
        event.endDate = hasEndDate ? endDate : nil
        event.eventType = eventType
        event.status = status
        event.budget = budget
        event.isAllDay = isAllDay
        
        viewModel.updateEvent(event)
        dismiss()
    }
    
    private func deleteEvent() {
        viewModel.deleteEvent(event)
        dismiss()
    }
}

struct AddTaskView: View {
    let event: Event
    let viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var taskDescription = ""
    @State private var priority: TaskPriority = .medium
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    AsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                Text("新しいタスク")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaDarkSlate"))
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("タスク名 *")
                                        .font(.subheadline)
                                        .foregroundColor(Color("AsaMutedSage"))
                                    TextField("タスク名を入力", text: $title)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("優先度")
                                        .font(.subheadline)
                                        .foregroundColor(Color("AsaMutedSage"))
                                    
                                    Picker("優先度", selection: $priority) {
                                        ForEach(TaskPriority.allCases, id: \.self) { taskPriority in
                                            HStack {
                                                Image(systemName: taskPriority.iconName)
                                                Text(taskPriority.rawValue)
                                            }
                                            .tag(taskPriority)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("説明（オプション）")
                                        .font(.subheadline)
                                        .foregroundColor(Color("AsaMutedSage"))
                                    
                                    TextEditor(text: $taskDescription)
                                        .frame(minHeight: 80)
                                        .padding(8)
                                        .background(Color("AsaSoftCream").opacity(0.3))
                                        .cornerRadius(8)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Toggle("期限を設定", isOn: $hasDueDate)
                                        .toggleStyle(SwitchToggleStyle(tint: Color("AsaCoffeeBrown")))
                                    
                                    if hasDueDate {
                                        DatePicker(
                                            "期限日",
                                            selection: $dueDate,
                                            displayedComponents: [.date]
                                        )
                                        .datePickerStyle(CompactDatePickerStyle())
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("タスク追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        createTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func createTask() {
        viewModel.addTask(
            to: event,
            title: title,
            description: taskDescription,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil
        )
        dismiss()
    }
}

struct AddParticipantView: View {
    let event: Event
    let viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var role = "ゲスト"
    @State private var status: ParticipantStatus = .invited
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    AsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                Text("新しい参加者")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaDarkSlate"))
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("名前 *")
                                        .font(.subheadline)
                                        .foregroundColor(Color("AsaMutedSage"))
                                    TextField("参加者の名前を入力", text: $name)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("役割")
                                        .font(.subheadline)
                                        .foregroundColor(Color("AsaMutedSage"))
                                    TextField("役割（例：主催者、司会者）", text: $role)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("参加状況")
                                        .font(.subheadline)
                                        .foregroundColor(Color("AsaMutedSage"))
                                    
                                    Picker("参加状況", selection: $status) {
                                        ForEach(ParticipantStatus.allCases, id: \.self) { participantStatus in
                                            HStack {
                                                Image(systemName: participantStatus.iconName)
                                                Text(participantStatus.rawValue)
                                            }
                                            .tag(participantStatus)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .padding()
                                    .background(Color("AsaSoftCream").opacity(0.3))
                                    .cornerRadius(8)
                                }
                                
                                Divider()
                                
                                Text("連絡先（オプション）")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("AsaDarkSlate"))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    TextField("メールアドレス", text: $email)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.emailAddress)
                                    
                                    TextField("電話番号", text: $phone)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.phonePad)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("参加者追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        createParticipant()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func createParticipant() {
        viewModel.addParticipant(
            to: event,
            name: name,
            email: email,
            phone: phone,
            role: role.isEmpty ? "ゲスト" : role
        )
        dismiss()
    }
}

struct EditParticipantView: View {
    let participant: Participant
    let viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var email: String
    @State private var phone: String
    @State private var role: String
    @State private var status: ParticipantStatus
    @State private var notes: String
    
    init(participant: Participant, viewModel: EventViewModel) {
        self.participant = participant
        self.viewModel = viewModel
        
        _name = State(initialValue: participant.name)
        _email = State(initialValue: participant.email)
        _phone = State(initialValue: participant.phone)
        _role = State(initialValue: participant.role)
        _status = State(initialValue: participant.status)
        _notes = State(initialValue: participant.notes)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    AsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "person.circle")
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                Text("参加者編集")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaDarkSlate"))
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("名前 *")
                                        .font(.subheadline)
                                        .foregroundColor(Color("AsaMutedSage"))
                                    TextField("参加者の名前を入力", text: $name)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("役割")
                                        .font(.subheadline)
                                        .foregroundColor(Color("AsaMutedSage"))
                                    TextField("役割（例：主催者、司会者）", text: $role)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("参加状況")
                                        .font(.subheadline)
                                        .foregroundColor(Color("AsaMutedSage"))
                                    
                                    Picker("参加状況", selection: $status) {
                                        ForEach(ParticipantStatus.allCases, id: \.self) { participantStatus in
                                            HStack {
                                                Image(systemName: participantStatus.iconName)
                                                Text(participantStatus.rawValue)
                                            }
                                            .tag(participantStatus)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .padding()
                                    .background(Color("AsaSoftCream").opacity(0.3))
                                    .cornerRadius(8)
                                }
                                
                                Divider()
                                
                                Text("連絡先")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("AsaDarkSlate"))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    TextField("メールアドレス", text: $email)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.emailAddress)
                                    
                                    TextField("電話番号", text: $phone)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.phonePad)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("備考")
                                        .font(.subheadline)
                                        .foregroundColor(Color("AsaMutedSage"))
                                    
                                    TextEditor(text: $notes)
                                        .frame(minHeight: 60)
                                        .padding(8)
                                        .background(Color("AsaSoftCream").opacity(0.3))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("参加者編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        updateParticipant()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func updateParticipant() {
        participant.name = name
        participant.email = email
        participant.phone = phone
        participant.role = role.isEmpty ? "ゲスト" : role
        participant.status = status
        participant.notes = notes
        
        viewModel.updateParticipant(participant)
        dismiss()
    }
}

struct EditTaskView: View {
    let task: EventTask
    let viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var taskDescription: String
    @State private var priority: TaskPriority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    
    init(task: EventTask, viewModel: EventViewModel) {
        self.task = task
        self.viewModel = viewModel
        
        _title = State(initialValue: task.title)
        _taskDescription = State(initialValue: task.taskDescription)
        _priority = State(initialValue: task.priority)
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? Date())
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    AsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "pencil.circle")
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                Text("タスク編集")
                                    .font(.headline)
                                    .foregroundColor(Color("AsaDarkSlate"))
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("タスク名 *")
                                        .font(.subheadline)
                                        .foregroundColor(Color("AsaMutedSage"))
                                    TextField("タスク名を入力", text: $title)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("優先度")
                                        .font(.subheadline)
                                        .foregroundColor(Color("AsaMutedSage"))
                                    
                                    Picker("優先度", selection: $priority) {
                                        ForEach(TaskPriority.allCases, id: \.self) { taskPriority in
                                            HStack {
                                                Image(systemName: taskPriority.iconName)
                                                Text(taskPriority.rawValue)
                                            }
                                            .tag(taskPriority)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("説明（オプション）")
                                        .font(.subheadline)
                                        .foregroundColor(Color("AsaMutedSage"))
                                    
                                    TextEditor(text: $taskDescription)
                                        .frame(minHeight: 80)
                                        .padding(8)
                                        .background(Color("AsaSoftCream").opacity(0.3))
                                        .cornerRadius(8)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Toggle("期限を設定", isOn: $hasDueDate)
                                        .toggleStyle(SwitchToggleStyle(tint: Color("AsaCoffeeBrown")))
                                    
                                    if hasDueDate {
                                        DatePicker(
                                            "期限日",
                                            selection: $dueDate,
                                            displayedComponents: [.date]
                                        )
                                        .datePickerStyle(CompactDatePickerStyle())
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("タスク編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        updateTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func updateTask() {
        task.title = title
        task.taskDescription = taskDescription
        task.priority = priority
        task.dueDate = hasDueDate ? dueDate : nil
        
        viewModel.updateTask(task)
        dismiss()
    }
}

struct TemplateSelectionView: View {
    let templates: [EventTemplate]
    @Binding var selectedTemplate: EventTemplate?
    let onTemplateSelected: (EventTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(templates, id: \.id) { template in
                    Button(action: {
                        onTemplateSelected(template)
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: template.eventType.iconName)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                
                                Text(template.name)
                                    .font(.headline)
                                    .foregroundColor(Color("AsaDarkSlate"))
                                
                                Spacer()
                                
                                if selectedTemplate?.id == template.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color("AsaCoffeeBrown"))
                                }
                            }
                            
                            if !template.templateDescription.isEmpty {
                                Text(template.templateDescription)
                                    .font(.caption)
                                    .foregroundColor(Color("AsaMutedSage"))
                                    .lineLimit(2)
                            }
                            
                            if template.suggestedBudget > 0 {
                                Text("予算目安: ¥\(Int(template.suggestedBudget))")
                                    .font(.caption)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("テンプレート選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddShoppingItemView: View {
    let event: Event
    let viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var itemDescription = ""
    @State private var category: ShoppingCategory = .other
    @State private var quantity = 1
    @State private var estimatedPrice: Double = 0.0
    @State private var store = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    basicInfoSection
                    
                    categoryAndQuantitySection
                    
                    priceAndStoreSection
                    
                    notesSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("アイテム追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        addShoppingItem()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private var basicInfoSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "cart.badge.plus")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("基本情報")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("アイテム名 *")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        TextField("アイテム名を入力", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("説明（オプション）")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        TextField("詳細説明", text: $itemDescription)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
        }
    }
    
    private var categoryAndQuantitySection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "tag")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("カテゴリ・数量")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("カテゴリ")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Picker("カテゴリ", selection: $category) {
                            ForEach(ShoppingCategory.allCases, id: \.self) { shoppingCategory in
                                HStack {
                                    Image(systemName: shoppingCategory.iconName)
                                    Text(shoppingCategory.rawValue)
                                }
                                .tag(shoppingCategory)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color("AsaSoftCream").opacity(0.3))
                        .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("数量")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        HStack {
                            Button(action: {
                                if quantity > 1 { quantity -= 1 }
                            }) {
                                Image(systemName: "minus.circle")
                                    .font(.title2)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                            }
                            .disabled(quantity <= 1)
                            
                            Text("\(quantity)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("AsaDarkSlate"))
                                .frame(minWidth: 50)
                            
                            Button(action: {
                                quantity += 1
                            }) {
                                Image(systemName: "plus.circle")
                                    .font(.title2)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    private var priceAndStoreSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "yensign.circle")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("価格・購入予定店舗")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("予想価格（円）")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        TextField("0", value: $estimatedPrice, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        if quantity > 1 {
                            Text("総額: ¥\(Int(estimatedPrice * Double(quantity)))")
                                .font(.caption)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("購入予定店舗（オプション）")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        TextField("店舗名", text: $store)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
        }
    }
    
    private var notesSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("備考")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("備考（オプション）")
                        .font(.subheadline)
                        .foregroundColor(Color("AsaMutedSage"))
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color("AsaSoftCream").opacity(0.3))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private func addShoppingItem() {
        viewModel.addShoppingItem(
            to: event,
            name: name,
            category: category,
            quantity: quantity,
            estimatedPrice: estimatedPrice
        )
        
        // 新しく作成されたアイテムの追加情報を設定
        if let newItem = event.shoppingItems.last {
            newItem.itemDescription = itemDescription
            newItem.store = store
            newItem.notes = notes
            viewModel.updateShoppingItem(newItem)
        }
        
        dismiss()
    }
}

struct EditShoppingItemView: View {
    let item: ShoppingItem
    let viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var itemDescription: String
    @State private var category: ShoppingCategory
    @State private var quantity: Int
    @State private var estimatedPrice: Double
    @State private var actualPrice: Double
    @State private var store: String
    @State private var notes: String
    @State private var isPurchased: Bool
    
    init(item: ShoppingItem, viewModel: EventViewModel) {
        self.item = item
        self.viewModel = viewModel
        
        _name = State(initialValue: item.name)
        _itemDescription = State(initialValue: item.itemDescription)
        _category = State(initialValue: item.category)
        _quantity = State(initialValue: item.quantity)
        _estimatedPrice = State(initialValue: item.estimatedPrice)
        _actualPrice = State(initialValue: item.actualPrice)
        _store = State(initialValue: item.store)
        _notes = State(initialValue: item.notes)
        _isPurchased = State(initialValue: item.isPurchased)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    basicInfoSection
                    
                    categoryAndQuantitySection
                    
                    priceSection
                    
                    storeAndNotesSection
                    
                    if isPurchased {
                        purchaseInfoSection
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("アイテム編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        updateShoppingItem()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private var basicInfoSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("基本情報")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                    
                    Toggle("購入済み", isOn: $isPurchased)
                        .toggleStyle(SwitchToggleStyle(tint: Color.green))
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("アイテム名 *")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        TextField("アイテム名を入力", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("説明")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        TextField("詳細説明", text: $itemDescription)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
        }
    }
    
    private var categoryAndQuantitySection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "tag")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("カテゴリ・数量")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("カテゴリ")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Picker("カテゴリ", selection: $category) {
                            ForEach(ShoppingCategory.allCases, id: \.self) { shoppingCategory in
                                HStack {
                                    Image(systemName: shoppingCategory.iconName)
                                    Text(shoppingCategory.rawValue)
                                }
                                .tag(shoppingCategory)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color("AsaSoftCream").opacity(0.3))
                        .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("数量")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        HStack {
                            Button(action: {
                                if quantity > 1 { quantity -= 1 }
                            }) {
                                Image(systemName: "minus.circle")
                                    .font(.title2)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                            }
                            .disabled(quantity <= 1)
                            
                            Text("\(quantity)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("AsaDarkSlate"))
                                .frame(minWidth: 50)
                            
                            Button(action: {
                                quantity += 1
                            }) {
                                Image(systemName: "plus.circle")
                                    .font(.title2)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    private var priceSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "yensign.circle")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("価格情報")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("予想価格（円）")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        TextField("0", value: $estimatedPrice, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                    
                    if isPurchased {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("実際の価格（円）")
                                .font(.subheadline)
                                .foregroundColor(Color("AsaMutedSage"))
                            
                            TextField("0", value: $actualPrice, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                    }
                    
                    if quantity > 1 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("予想総額: ¥\(Int(estimatedPrice * Double(quantity)))")
                                .font(.caption)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            if isPurchased && actualPrice > 0 {
                                Text("実際総額: ¥\(Int(actualPrice * Double(quantity)))")
                                    .font(.caption)
                                    .foregroundColor(actualPrice > estimatedPrice ? Color.red : Color.green)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var storeAndNotesSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "storefront")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("店舗・備考")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("購入店舗")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        TextField("店舗名", text: $store)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("備考")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color("AsaSoftCream").opacity(0.3))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var purchaseInfoSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.green)
                    Text("購入情報")
                        .font(.headline)
                        .foregroundColor(Color("AsaDarkSlate"))
                    Spacer()
                }
                
                if let purchaseDate = item.purchasedAt {
                    Text("購入日: \(purchaseDate, style: .date)")
                        .font(.subheadline)
                        .foregroundColor(Color("AsaMutedSage"))
                }
                
                let difference = actualPrice - estimatedPrice
                if difference != 0 {
                    HStack {
                        Text("予算との差額:")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Text("\(difference > 0 ? "+" : "")¥\(Int(difference * Double(quantity)))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(difference > 0 ? Color.red : Color.green)
                    }
                }
            }
        }
    }
    
    private func updateShoppingItem() {
        item.name = name
        item.itemDescription = itemDescription
        item.category = category
        item.quantity = quantity
        item.estimatedPrice = estimatedPrice
        item.store = store
        item.notes = notes
        
        // 購入状況の更新
        if isPurchased != item.isPurchased {
            if isPurchased {
                item.markAsPurchased(actualPrice: actualPrice > 0 ? actualPrice : estimatedPrice)
            } else {
                item.markAsUnpurchased()
            }
        } else if isPurchased && actualPrice != item.actualPrice {
            item.actualPrice = actualPrice
        }
        
        viewModel.updateShoppingItem(item)
        dismiss()
    }
}

#Preview {
    ContentView()
        .modelContainer(ModelContainer.shared)
}
