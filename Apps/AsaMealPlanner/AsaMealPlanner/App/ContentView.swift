import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var weeklyPlans: [WeeklyPlan]
    @State private var selectedPlan: WeeklyPlan?
    
    var body: some View {
        Group {
            if let plan = currentPlan {
                MainTabView(weeklyPlan: plan)
            } else {
                WelcomeView()
            }
        }
        .onAppear {
            setupDefaultPlanIfNeeded()
        }
    }
    
    // MARK: - Computed Properties
    private var currentPlan: WeeklyPlan? {
        return selectedPlan ?? weeklyPlans.first { $0.isActive }
    }
    
    // MARK: - Methods
    private func setupDefaultPlanIfNeeded() {
        if weeklyPlans.isEmpty {
            let defaultPlan = WeeklyPlan(
                planName: "今週の食事プラン",
                startDate: startOfWeek(),
                planDescription: "朝活パパエンジニアの健康的な1週間プラン"
            )
            modelContext.insert(defaultPlan)
            selectedPlan = defaultPlan
            
            // サンプルデータを追加（初回のみ）
            addSampleMeals(to: defaultPlan)
        }
    }
    
    private func startOfWeek() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysFromSunday = weekday - 1 // 日曜日を0として計算
        
        return calendar.date(byAdding: .day, value: -daysFromSunday, to: today) ?? today
    }
    
    private func addSampleMeals(to plan: WeeklyPlan) {
        let sampleMeals = [
            // 月曜日
            Meal(title: "和風オムレツ", mealDescription: "野菜たっぷりヘルシー朝食", mealType: .breakfast, dayOfWeek: 1),
            Meal(title: "親子丼", mealDescription: "お昼の定番丼もの", mealType: .lunch, dayOfWeek: 1),
            Meal(title: "鮭の塩焼き定食", mealDescription: "栄養バランス抜群の夕食", mealType: .dinner, dayOfWeek: 1),
            
            // 火曜日
            Meal(title: "トースト", mealDescription: "忙しい朝の簡単朝食", mealType: .breakfast, dayOfWeek: 2),
            Meal(title: "チキンカレー", mealDescription: "みんな大好きカレーライス", mealType: .lunch, dayOfWeek: 2),
            
            // 水曜日
            Meal(title: "フルーツヨーグルト", mealDescription: "軽やかな朝食", mealType: .breakfast, dayOfWeek: 3),
            Meal(title: "生姜焼き定食", mealDescription: "がっつりランチ", mealType: .lunch, dayOfWeek: 3),
        ]
        
        sampleMeals.forEach { meal in
            plan.addMeal(meal)
            modelContext.insert(meal)
            
            // サンプル食材を追加
            if meal.mealType == .breakfast {
                let ingredients = [
                    Ingredient(name: "卵", amount: 2, unit: "個", category: .other),
                    Ingredient(name: "玉ねぎ", amount: 0.5, unit: "個", category: .vegetable),
                ]
                ingredients.forEach { ingredient in
                    meal.addIngredient(ingredient)
                    modelContext.insert(ingredient)
                }
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    let weeklyPlan: WeeklyPlan
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WeeklyPlanView(weeklyPlan: weeklyPlan)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("週間プラン")
                }
                .tag(0)
            
            IngredientsListView(weeklyPlan: weeklyPlan)
                .tabItem {
                    Image(systemName: "cart")
                    Text("食材リスト")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("設定")
                }
                .tag(2)
        }
        .accentColor(Color("AsaCoffeeBrown"))
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                VStack(spacing: 8) {
                    Text("AsaMealPlanner")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("1週間の食事プランを\n簡単に作成・管理")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 16) {
                FeatureRow(icon: "calendar", title: "週間カレンダー", description: "7日分の食事を一覧表示")
                FeatureRow(icon: "cart", title: "食材リスト", description: "自動で買い物リストを生成")
                FeatureRow(icon: "heart.fill", title: "健康管理", description: "栄養バランスを考慮")
            }
            
            Text("データを準備中...")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .navigationTitle("食事プラン")
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color("AsaCoffeeBrown"))
                .frame(width: 30, alignment: .center)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Weekly Plan View
struct WeeklyPlanView: View {
    let weeklyPlan: WeeklyPlan
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDay = Calendar.current.component(.weekday, from: Date()) - 1
    
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    private let mealTypes = MealType.allCases
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 週間カレンダーヘッダー
                    weekHeaderView
                    
                    // 選択された日の詳細ビュー
                    selectedDayDetailView
                    
                    // 週間サマリー
                    weekSummaryView
                }
                .padding()
            }
            .navigationTitle("週間食事プラン")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - 週間カレンダーヘッダー
    private var weekHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(weeklyPlan.planName)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Text(weekDateRange)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 曜日選択タブ
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        DayTab(
                            dayName: weekdays[dayIndex],
                            dayNumber: dayNumber(for: dayIndex),
                            isSelected: selectedDay == dayIndex,
                            hasContent: weeklyPlan.getMeals(for: dayIndex).count > 0
                        )
                        .onTapGesture {
                            selectedDay = dayIndex
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 選択された日の詳細ビュー
    private var selectedDayDetailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(weekdays[selectedDay])曜日の食事")
                .font(.headline)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            ForEach(mealTypes, id: \.self) { mealType in
                MealTypeSection(
                    mealType: mealType,
                    meals: weeklyPlan.getMeals(for: selectedDay, type: mealType),
                    dayOfWeek: selectedDay,
                    weeklyPlan: weeklyPlan
                )
            }
        }
        .padding()
        .background(Color("AsaSoftCream").opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - 週間サマリー
    private var weekSummaryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("週間サマリー")
                .font(.headline)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            HStack {
                SummaryCard(
                    title: "総食事数",
                    value: "\(weeklyPlan.totalMeals)",
                    icon: "fork.knife"
                )
                
                Spacer()
                
                SummaryCard(
                    title: "計画済み日数",
                    value: "\(weeklyPlan.completedDays)/7",
                    icon: "calendar.badge.checkmark"
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    private var weekDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        
        let startDate = weeklyPlan.startDate
        let endDate = weeklyPlan.endDate
        
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    private func dayNumber(for dayIndex: Int) -> Int {
        let calendar = Calendar.current
        if let date = calendar.date(byAdding: .day, value: dayIndex, to: weeklyPlan.startDate) {
            return calendar.component(.day, from: date)
        }
        return 1
    }
}

// MARK: - Day Tab Component
struct DayTab: View {
    let dayName: String
    let dayNumber: Int
    let isSelected: Bool
    let hasContent: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayName)
                .font(.caption)
                .fontWeight(.medium)
            
            Text("\(dayNumber)")
                .font(.title3)
                .fontWeight(.semibold)
            
            if hasContent {
                Circle()
                    .fill(Color("AsaCoffeeBrown"))
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color("AsaCoffeeBrown") : Color.clear)
        )
        .foregroundColor(isSelected ? .white : Color("AsaDarkSlate"))
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Meal Type Section
struct MealTypeSection: View {
    let mealType: MealType
    let meals: [Meal]
    let dayOfWeek: Int
    let weeklyPlan: WeeklyPlan
    
    @State private var showingMealEditor = false
    @State private var selectedMeal: Meal? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(mealType.emoji) \(mealType.displayName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Spacer()
                
                if meals.isEmpty {
                    Button(action: {
                        selectedMeal = nil
                        showingMealEditor = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                }
            }
            
            if meals.isEmpty {
                Text("食事が設定されていません")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(meals, id: \.id) { meal in
                    MealCard(meal: meal)
                        .onTapGesture {
                            selectedMeal = meal
                            showingMealEditor = true
                        }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingMealEditor) {
            MealEditView(
                weeklyPlan: weeklyPlan,
                selectedDay: dayOfWeek,
                meal: selectedMeal
            )
        }
    }
}

// MARK: - Meal Card Component
struct MealCard: View {
    let meal: Meal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                if !meal.mealDescription.isEmpty {
                    Text(meal.mealDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if meal.totalIngredients > 0 {
                    Label("\(meal.totalIngredients)品目", systemImage: "list.bullet")
                        .font(.caption2)
                        .foregroundColor(Color("AsaMutedSage"))
                }
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("\(meal.estimatedCookingTime)分")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(meal.servings)人分")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color("AsaSoftCream").opacity(0.5))
        .cornerRadius(6)
    }
}

// MARK: - Summary Card Component
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct IngredientsListView: View {
    let weeklyPlan: WeeklyPlan
    @State private var consolidatedIngredients: [ConsolidatedIngredient] = []
    @State private var selectedCategory: IngredientCategory? = nil
    
    private let categories = IngredientCategory.allCases
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 統計ヘッダー
                ingredientsStatsView
                
                // カテゴリーフィルター
                categoryFilterView
                
                // 食材リスト
                ingredientsList
            }
            .navigationTitle("買い物リスト")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        updateIngredientsList()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
            .onAppear {
                updateIngredientsList()
            }
        }
    }
    
    // MARK: - 統計ヘッダー
    private var ingredientsStatsView: some View {
        VStack(spacing: 12) {
            HStack {
                StatsCard(
                    title: "総品目数",
                    value: "\(consolidatedIngredients.count)",
                    icon: "list.bullet",
                    color: Color("AsaCoffeeBrown")
                )
                
                Spacer()
                
                StatsCard(
                    title: "購入済み",
                    value: "\(purchasedCount)/\(consolidatedIngredients.count)",
                    icon: "checkmark.circle.fill",
                    color: Color("AsaMutedSage")
                )
            }
            .padding(.horizontal)
            
            ProgressView(value: progressValue)
                .progressViewStyle(LinearProgressViewStyle(tint: Color("AsaMutedSage")))
                .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(Color("AsaSoftCream").opacity(0.3))
    }
    
    // MARK: - カテゴリーフィルター
    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全カテゴリーボタン
                CategoryChip(
                    title: "すべて",
                    emoji: "🛒",
                    isSelected: selectedCategory == nil,
                    count: consolidatedIngredients.count
                )
                .onTapGesture {
                    selectedCategory = nil
                }
                
                // 各カテゴリーボタン
                ForEach(categories, id: \.self) { category in
                    CategoryChip(
                        title: category.displayName,
                        emoji: category.emoji,
                        isSelected: selectedCategory == category,
                        count: ingredientCount(for: category)
                    )
                    .onTapGesture {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - 食材リスト
    private var ingredientsList: some View {
        List {
            ForEach(filteredIngredients, id: \.id) { ingredient in
                IngredientRow(ingredient: ingredient)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Helper Properties
    private var filteredIngredients: [ConsolidatedIngredient] {
        if let selectedCategory = selectedCategory {
            return consolidatedIngredients.filter { $0.category == selectedCategory }
        }
        return consolidatedIngredients
    }
    
    private var purchasedCount: Int {
        consolidatedIngredients.filter { $0.isPurchased }.count
    }
    
    private var progressValue: Double {
        guard !consolidatedIngredients.isEmpty else { return 0.0 }
        return Double(purchasedCount) / Double(consolidatedIngredients.count)
    }
    
    // MARK: - Helper Methods
    private func updateIngredientsList() {
        consolidatedIngredients = weeklyPlan.getConsolidatedIngredients()
    }
    
    private func ingredientCount(for category: IngredientCategory) -> Int {
        consolidatedIngredients.filter { $0.category == category }.count
    }
}

// MARK: - Stats Card Component
struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Category Chip Component
struct CategoryChip: View {
    let title: String
    let emoji: String
    let isSelected: Bool
    let count: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Text(emoji)
                .font(.caption)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            if count > 0 {
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : Color("AsaCoffeeBrown"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color("AsaCoffeeBrown").opacity(0.3) : Color("AsaSoftCream"))
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? Color("AsaCoffeeBrown") : Color.white)
        )
        .foregroundColor(isSelected ? .white : Color("AsaDarkSlate"))
        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Ingredient Row Component
struct IngredientRow: View {
    @ObservedObject var ingredient: ConsolidatedIngredient
    @State private var showMealDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // チェックボックス
                Button(action: {
                    ingredient.isPurchased.toggle()
                }) {
                    Image(systemName: ingredient.isPurchased ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(ingredient.isPurchased ? Color("AsaMutedSage") : Color.gray.opacity(0.5))
                }
                
                // 食材情報
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(ingredient.category.emoji)
                            .font(.caption)
                        
                        Text(ingredient.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(ingredient.isPurchased ? .secondary : Color("AsaDarkSlate"))
                            .strikethrough(ingredient.isPurchased)
                        
                        Spacer()
                        
                        Text(ingredient.displayAmount)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                    
                    // 使用される料理名
                    if !ingredient.mealTitles.isEmpty {
                        Text("使用: \(Array(ingredient.mealTitles).joined(separator: "、"))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                // 詳細表示ボタン
                Button(action: {
                    showMealDetails.toggle()
                }) {
                    Image(systemName: showMealDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            // 詳細情報（展開時）
            if showMealDetails && !ingredient.mealTitles.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("この食材を使用する料理:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    ForEach(Array(ingredient.mealTitles), id: \.self) { mealTitle in
                        HStack {
                            Circle()
                                .fill(Color("AsaMutedSage"))
                                .frame(width: 4, height: 4)
                            
                            Text(mealTitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.leading, 32)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .animation(.easeInOut(duration: 0.3), value: showMealDetails)
    }
}

// MARK: - Meal Edit View
struct MealEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let weeklyPlan: WeeklyPlan
    let selectedDay: Int
    @State var meal: Meal?
    
    @State private var title = ""
    @State private var mealDescription = ""
    @State private var selectedMealType: MealType = .breakfast
    @State private var estimatedCookingTime = 30
    @State private var servings = 2
    @State private var ingredients: [Ingredient] = []
    
    @State private var showingAddIngredient = false
    @State private var newIngredientName = ""
    @State private var newIngredientAmount = 1.0
    @State private var newIngredientUnit = "個"
    @State private var newIngredientCategory: IngredientCategory = .other
    
    private let units = ["個", "g", "ml", "大さじ", "小さじ", "カップ", "合", "本", "枚", "パック"]
    private let cookingTimeOptions = Array(stride(from: 10, through: 180, by: 10))
    private let servingOptions = Array(1...10)
    
    var isEditing: Bool {
        meal != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 基本情報セクション
                Section(header: Text("基本情報")) {
                    TextField("料理名", text: $title)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("説明（任意）", text: $mealDescription, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                    
                    Picker("食事の種類", selection: $selectedMealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            HStack {
                                Text(type.emoji)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // 調理情報セクション
                Section(header: Text("調理情報")) {
                    HStack {
                        Text("調理時間")
                        Spacer()
                        Picker("調理時間", selection: $estimatedCookingTime) {
                            ForEach(cookingTimeOptions, id: \.self) { time in
                                Text("\(time)分").tag(time)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    HStack {
                        Text("人数")
                        Spacer()
                        Picker("人数", selection: $servings) {
                            ForEach(servingOptions, id: \.self) { serving in
                                Text("\(serving)人分").tag(serving)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                // 食材セクション
                Section(header: 
                    HStack {
                        Text("食材")
                        Spacer()
                        Button("追加") {
                            showingAddIngredient = true
                        }
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                ) {
                    if ingredients.isEmpty {
                        Text("食材を追加してください")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(ingredients.indices, id: \.self) { index in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ingredients[index].name)
                                        .fontWeight(.medium)
                                    
                                    HStack {
                                        Text(ingredients[index].category.emoji)
                                            .font(.caption)
                                        Text(ingredients[index].category.displayName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("\(ingredients[index].amount, specifier: "%.1f")\(ingredients[index].unit)")
                                    .font(.subheadline)
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                            }
                        }
                        .onDelete(perform: deleteIngredient)
                    }
                }
            }
            .navigationTitle(isEditing ? "食事を編集" : "新しい食事")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveMeal()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddIngredient) {
                addIngredientSheet
            }
            .onAppear {
                setupEditMode()
            }
        }
    }
    
    // MARK: - Add Ingredient Sheet
    private var addIngredientSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("食材情報")) {
                    TextField("食材名", text: $newIngredientName)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        Text("数量")
                        Spacer()
                        TextField("数量", value: $newIngredientAmount, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                    }
                    
                    Picker("単位", selection: $newIngredientUnit) {
                        ForEach(units, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    .pickerStyle(.wheel)
                    
                    Picker("カテゴリー", selection: $newIngredientCategory) {
                        ForEach(IngredientCategory.allCases, id: \.self) { category in
                            HStack {
                                Text(category.emoji)
                                Text(category.displayName)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("食材を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        resetAddIngredientForm()
                        showingAddIngredient = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        addIngredient()
                        resetAddIngredientForm()
                        showingAddIngredient = false
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .disabled(newIngredientName.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func setupEditMode() {
        if let meal = meal {
            title = meal.title
            mealDescription = meal.mealDescription
            selectedMealType = meal.mealType
            estimatedCookingTime = meal.estimatedCookingTime
            servings = meal.servings
            ingredients = meal.ingredients
        }
    }
    
    private func saveMeal() {
        let mealToSave: Meal
        
        if let existingMeal = meal {
            // 既存の食事を更新
            existingMeal.title = title
            existingMeal.mealDescription = mealDescription
            existingMeal.mealType = selectedMealType
            existingMeal.estimatedCookingTime = estimatedCookingTime
            existingMeal.servings = servings
            existingMeal.updatedAt = Date()
            
            // 既存の食材を削除してから新しい食材を追加
            existingMeal.ingredients.removeAll()
            ingredients.forEach { ingredient in
                existingMeal.addIngredient(ingredient)
                modelContext.insert(ingredient)
            }
            
            mealToSave = existingMeal
        } else {
            // 新しい食事を作成
            mealToSave = Meal(
                title: title,
                mealDescription: mealDescription,
                mealType: selectedMealType,
                dayOfWeek: selectedDay,
                estimatedCookingTime: estimatedCookingTime,
                servings: servings
            )
            
            weeklyPlan.addMeal(mealToSave)
            modelContext.insert(mealToSave)
            
            // 食材を追加
            ingredients.forEach { ingredient in
                mealToSave.addIngredient(ingredient)
                modelContext.insert(ingredient)
            }
        }
        
        // 変更を保存
        do {
            try modelContext.save()
        } catch {
            print("Error saving meal: \(error)")
        }
    }
    
    private func addIngredient() {
        let ingredient = Ingredient(
            name: newIngredientName,
            amount: newIngredientAmount,
            unit: newIngredientUnit,
            category: newIngredientCategory
        )
        ingredients.append(ingredient)
    }
    
    private func deleteIngredient(offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }
    
    private func resetAddIngredientForm() {
        newIngredientName = ""
        newIngredientAmount = 1.0
        newIngredientUnit = "個"
        newIngredientCategory = .other
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Text("設定ビュー（実装予定）")
                .navigationTitle("設定")
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .modelContainer(previewContainer)
}