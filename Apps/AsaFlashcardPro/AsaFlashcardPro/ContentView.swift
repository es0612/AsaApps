import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CategoryListView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("カテゴリ")
                }
                .tag(0)
            
            StudyModeSelectionView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("学習")
                }
                .tag(1)
            
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("統計")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("設定")
                }
                .tag(3)
        }
        .accentColor(Color("AsaCoffeeBrown"))
        .onAppear {
            setupInitialDataIfNeeded()
            // 既存ユーザー環境でも不足分のみを追加入れ
            upgradeSampleDataIfNeeded()
        }
    }
    
    private func setupInitialDataIfNeeded() {
        // 初回起動時のみサンプルデータを作成
        if categories.isEmpty {
            createSampleData()
        }
    }
    
    private func createSampleData() {
        // 英語基礎カテゴリ
        let englishCategory = Category(name: "英語基礎", icon: "textbook", color: "AsaCoffeeBrown")
        modelContext.insert(englishCategory)
        
        let englishFlashcards = [
            // 基本単語（既存＋拡張）
            Flashcard(word: "Apple", meaning: "りんご", example: "I eat an apple every day.", pronunciation: "ˈæpəl", category: englishCategory),
            Flashcard(word: "Book", meaning: "本", example: "This is a good book.", pronunciation: "bʊk", category: englishCategory),
            Flashcard(word: "Cat", meaning: "猫", example: "The cat is sleeping.", pronunciation: "kæt", category: englishCategory),
            Flashcard(word: "Dog", meaning: "犬", example: "My dog likes to play.", pronunciation: "dɔːɡ", category: englishCategory),
            Flashcard(word: "House", meaning: "家", example: "I live in a big house.", pronunciation: "haʊs", category: englishCategory),
            // 日常基本語彙
            Flashcard(word: "Water", meaning: "水", example: "I drink water every morning.", pronunciation: "ˈwɔːtər", category: englishCategory),
            Flashcard(word: "Food", meaning: "食べ物", example: "This food is delicious.", pronunciation: "fuːd", category: englishCategory),
            Flashcard(word: "Time", meaning: "時間", example: "What time is it?", pronunciation: "taɪm", category: englishCategory),
            Flashcard(word: "Work", meaning: "仕事", example: "I go to work by train.", pronunciation: "wərk", category: englishCategory),
            Flashcard(word: "Family", meaning: "家族", example: "I love my family.", pronunciation: "ˈfæməli", category: englishCategory),
            // 朝活パパ関連
            Flashcard(word: "Child", meaning: "子ども", example: "My child is sleeping.", pronunciation: "tʃaɪld", category: englishCategory),
            Flashcard(word: "Morning", meaning: "朝", example: "Good morning!", pronunciation: "ˈmɔːrnɪŋ", category: englishCategory),
            Flashcard(word: "Coffee", meaning: "コーヒー", example: "I drink coffee in the morning.", pronunciation: "ˈkɔːfi", category: englishCategory),
            Flashcard(word: "Computer", meaning: "コンピューター", example: "I work on my computer.", pronunciation: "kəmˈpjuːtər", category: englishCategory),
            Flashcard(word: "Phone", meaning: "電話", example: "My phone is ringing.", pronunciation: "foʊn", category: englishCategory),
            // 移動・場所
            Flashcard(word: "Car", meaning: "車", example: "I drive my car to work.", pronunciation: "kɑːr", category: englishCategory),
            Flashcard(word: "Train", meaning: "電車", example: "I take the train every day.", pronunciation: "treɪn", category: englishCategory),
            Flashcard(word: "School", meaning: "学校", example: "My child goes to school.", pronunciation: "skuːl", category: englishCategory),
            Flashcard(word: "Park", meaning: "公園", example: "We play in the park.", pronunciation: "pɑːrk", category: englishCategory),
            Flashcard(word: "Friend", meaning: "友達", example: "He is my best friend.", pronunciation: "frend", category: englishCategory),
            // 感情・形容詞
            Flashcard(word: "Love", meaning: "愛", example: "I love you.", pronunciation: "lʌv", category: englishCategory),
            Flashcard(word: "Happy", meaning: "幸せ", example: "I am very happy today.", pronunciation: "ˈhæpi", category: englishCategory),
            Flashcard(word: "Good", meaning: "良い", example: "Have a good day!", pronunciation: "ɡʊd", category: englishCategory),
            Flashcard(word: "New", meaning: "新しい", example: "I bought a new book.", pronunciation: "nuː", category: englishCategory),
            Flashcard(word: "Big", meaning: "大きい", example: "This is a big house.", pronunciation: "bɪɡ", category: englishCategory),
            // 基本語彙
            Flashcard(word: "Small", meaning: "小さい", example: "The cat is small.", pronunciation: "smɔːl", category: englishCategory),
            Flashcard(word: "Red", meaning: "赤", example: "I like red apples.", pronunciation: "red", category: englishCategory),
            Flashcard(word: "Blue", meaning: "青", example: "The sky is blue.", pronunciation: "bluː", category: englishCategory),
            Flashcard(word: "Green", meaning: "緑", example: "Green tea is healthy.", pronunciation: "ɡriːn", category: englishCategory),
            Flashcard(word: "Today", meaning: "今日", example: "Today is a beautiful day.", pronunciation: "təˈdeɪ", category: englishCategory)
        ]
        
        for flashcard in englishFlashcards {
            modelContext.insert(flashcard)
            englishCategory.flashcards.append(flashcard)
        }
        
        // 日本語基礎カテゴリ
        let japaneseCategory = Category(name: "日本語基礎", icon: "character.book.closed", color: "AsaMocha")
        modelContext.insert(japaneseCategory)
        
        let japaneseFlashcards = [
            // 既存（自然・季節）
            Flashcard(word: "さくら", meaning: "桜", example: "春にさくらが咲きます。", pronunciation: "sakura", category: japaneseCategory),
            Flashcard(word: "やま", meaning: "山", example: "高いやまに登りました。", pronunciation: "yama", category: japaneseCategory),
            Flashcard(word: "うみ", meaning: "海", example: "夏にうみで泳ぎました。", pronunciation: "umi", category: japaneseCategory),
            // 基本ひらがな語彙
            Flashcard(word: "おはよう", meaning: "朝の挨拶", example: "おはようございます。", pronunciation: "ohayou", category: japaneseCategory),
            Flashcard(word: "ありがとう", meaning: "感謝の言葉", example: "ありがとうございました。", pronunciation: "arigatou", category: japaneseCategory),
            Flashcard(word: "すみません", meaning: "謝罪・呼びかけ", example: "すみません、遅れました。", pronunciation: "sumimasen", category: japaneseCategory),
            Flashcard(word: "げんき", meaning: "元気", example: "今日はげんきです。", pronunciation: "genki", category: japaneseCategory),
            Flashcard(word: "いえ", meaning: "家", example: "いえに帰ります。", pronunciation: "ie", category: japaneseCategory),
            // 家族関係
            Flashcard(word: "おかあさん", meaning: "お母さん", example: "おかあさんは料理が上手です。", pronunciation: "okaasan", category: japaneseCategory),
            Flashcard(word: "おとうさん", meaning: "お父さん", example: "おとうさんは会社で働いています。", pronunciation: "otousan", category: japaneseCategory),
            Flashcard(word: "こども", meaning: "子ども", example: "こどもが公園で遊んでいます。", pronunciation: "kodomo", category: japaneseCategory),
            Flashcard(word: "かぞく", meaning: "家族", example: "かぞくでお出かけしました。", pronunciation: "kazoku", category: japaneseCategory),
            // 日常生活
            Flashcard(word: "みず", meaning: "水", example: "みずを飲みます。", pronunciation: "mizu", category: japaneseCategory),
            Flashcard(word: "たべもの", meaning: "食べ物", example: "おいしいたべものを食べました。", pronunciation: "tabemono", category: japaneseCategory),
            Flashcard(word: "でんしゃ", meaning: "電車", example: "でんしゃで会社に行きます。", pronunciation: "densha", category: japaneseCategory),
            Flashcard(word: "がっこう", meaning: "学校", example: "こどもはがっこうが好きです。", pronunciation: "gakkou", category: japaneseCategory),
            // 色・形
            Flashcard(word: "あか", meaning: "赤", example: "あかいりんごを食べました。", pronunciation: "aka", category: japaneseCategory),
            Flashcard(word: "あお", meaning: "青", example: "そらはあおいです。", pronunciation: "ao", category: japaneseCategory),
            Flashcard(word: "きいろ", meaning: "黄色", example: "きいろいはなが咲いています。", pronunciation: "kiiro", category: japaneseCategory),
            // 時間・季節
            Flashcard(word: "あさ", meaning: "朝", example: "あさ早く起きます。", pronunciation: "asa", category: japaneseCategory),
            Flashcard(word: "よる", meaning: "夜", example: "よるは静かです。", pronunciation: "yoru", category: japaneseCategory),
            Flashcard(word: "はる", meaning: "春", example: "はるになると花が咲きます。", pronunciation: "haru", category: japaneseCategory),
            Flashcard(word: "なつ", meaning: "夏", example: "なつは暑いです。", pronunciation: "natsu", category: japaneseCategory),
            // 基本動作
            Flashcard(word: "たべる", meaning: "食べる", example: "ごはんをたべます。", pronunciation: "taberu", category: japaneseCategory),
            Flashcard(word: "のむ", meaning: "飲む", example: "みずをのみます。", pronunciation: "nomu", category: japaneseCategory),
            Flashcard(word: "ねる", meaning: "寝る", example: "よるはやくねます。", pronunciation: "neru", category: japaneseCategory)
        ]
        
        for flashcard in japaneseFlashcards {
            modelContext.insert(flashcard)
            japaneseCategory.flashcards.append(flashcard)
        }
        
        // プログラミング用語カテゴリ
        let programmingCategory = Category(name: "プログラミング用語", icon: "laptopcomputer", color: "AsaMutedSage")
        modelContext.insert(programmingCategory)
        
        let programmingFlashcards = [
            // 基本概念（既存＋拡張）
            Flashcard(word: "Variable", meaning: "変数", example: "let variable = 'Hello'", category: programmingCategory),
            Flashcard(word: "Function", meaning: "関数", example: "func myFunction() { }", category: programmingCategory),
            Flashcard(word: "Array", meaning: "配列", example: "let array = [1, 2, 3]", category: programmingCategory),
            Flashcard(word: "Loop", meaning: "ループ", example: "for item in array { }", category: programmingCategory),
            // Swift基本型
            Flashcard(word: "String", meaning: "文字列型", example: "let name: String = \"Swift\"", category: programmingCategory),
            Flashcard(word: "Int", meaning: "整数型", example: "let count: Int = 42", category: programmingCategory),
            Flashcard(word: "Bool", meaning: "真偽値型", example: "let isActive: Bool = true", category: programmingCategory),
            Flashcard(word: "Optional", meaning: "オプショナル型", example: "var name: String? = nil", category: programmingCategory),
            // SwiftUI関連
            Flashcard(word: "View", meaning: "ビュー", example: "struct ContentView: View { }", category: programmingCategory),
            Flashcard(word: "State", meaning: "状態管理", example: "@State private var count = 0", category: programmingCategory),
            Flashcard(word: "Binding", meaning: "バインディング", example: "@Binding var isPresented: Bool", category: programmingCategory),
            Flashcard(word: "Observable", meaning: "監視可能", example: "@Observable class ViewModel { }", category: programmingCategory),
            // iOS開発
            Flashcard(word: "ViewController", meaning: "ビューコントローラー", example: "class MainViewController: UIViewController", category: programmingCategory),
            Flashcard(word: "Delegate", meaning: "デリゲート", example: "class MyClass: UITableViewDelegate", category: programmingCategory),
            Flashcard(word: "Protocol", meaning: "プロトコル", example: "protocol Drawable { }", category: programmingCategory),
            Flashcard(word: "Extension", meaning: "拡張", example: "extension String { }", category: programmingCategory),
            // 制御構文
            Flashcard(word: "If", meaning: "条件分岐", example: "if condition { /* code */ }", category: programmingCategory),
            Flashcard(word: "Guard", meaning: "ガード文", example: "guard let value = optional else { return }", category: programmingCategory),
            Flashcard(word: "Switch", meaning: "分岐文", example: "switch value { case 1: break }", category: programmingCategory),
            // データ構造
            Flashcard(word: "Dictionary", meaning: "辞書", example: "let dict = [\"key\": \"value\"]", category: programmingCategory),
            Flashcard(word: "Set", meaning: "セット", example: "let uniqueNumbers: Set = [1, 2, 3]", category: programmingCategory),
            Flashcard(word: "Tuple", meaning: "タプル", example: "let coordinates = (x: 10, y: 20)", category: programmingCategory),
            // 朝活パパエンジニア実用語彙
            Flashcard(word: "Debug", meaning: "デバッグ", example: #"print("Debug: \(value)")"#, category: programmingCategory),
            Flashcard(word: "Build", meaning: "ビルド", example: "Building project in Xcode", category: programmingCategory),
            Flashcard(word: "Commit", meaning: "コミット", example: "git commit -m \"Fix bug\"", category: programmingCategory)
        ]
        
        for flashcard in programmingFlashcards {
            modelContext.insert(flashcard)
            programmingCategory.flashcards.append(flashcard)
        }
        
        // TOEIC頻出語彙カテゴリ
        let toeicCategory = Category(name: "TOEIC頻出語彙", icon: "graduationcap.fill", color: "AsaDarkSlate")
        modelContext.insert(toeicCategory)
        
        let toeicFlashcards = [
            // ビジネス・会議
            Flashcard(word: "Meeting", meaning: "会議", example: "We have a meeting at 2 PM.", pronunciation: "ˈmiːtɪŋ", category: toeicCategory),
            Flashcard(word: "Schedule", meaning: "予定", example: "Please check your schedule.", pronunciation: "ˈʃedʒuːl", category: toeicCategory),
            Flashcard(word: "Project", meaning: "プロジェクト", example: "This project is important.", pronunciation: "ˈprɒdʒekt", category: toeicCategory),
            Flashcard(word: "Manager", meaning: "管理者", example: "The manager is in a meeting.", pronunciation: "ˈmænɪdʒər", category: toeicCategory),
            Flashcard(word: "Department", meaning: "部署", example: "Which department do you work in?", pronunciation: "dɪˈpɑːrtmənt", category: toeicCategory),
            // 旅行・出張
            Flashcard(word: "Flight", meaning: "飛行機", example: "My flight is delayed.", pronunciation: "flaɪt", category: toeicCategory),
            Flashcard(word: "Hotel", meaning: "ホテル", example: "I booked a hotel room.", pronunciation: "hoʊˈtel", category: toeicCategory),
            Flashcard(word: "Reservation", meaning: "予約", example: "I made a reservation for dinner.", pronunciation: "ˌrezərˈveɪʃən", category: toeicCategory),
            Flashcard(word: "Ticket", meaning: "チケット", example: "Don't forget your ticket.", pronunciation: "ˈtɪkɪt", category: toeicCategory),
            Flashcard(word: "Airport", meaning: "空港", example: "I'll pick you up at the airport.", pronunciation: "ˈerpɔːrt", category: toeicCategory),
            // 財務・お金
            Flashcard(word: "Budget", meaning: "予算", example: "We need to stay within budget.", pronunciation: "ˈbʌdʒɪt", category: toeicCategory),
            Flashcard(word: "Invoice", meaning: "請求書", example: "Please send me the invoice.", pronunciation: "ˈɪnvɔɪs", category: toeicCategory),
            Flashcard(word: "Payment", meaning: "支払い", example: "The payment is due tomorrow.", pronunciation: "ˈpeɪmənt", category: toeicCategory),
            Flashcard(word: "Revenue", meaning: "収益", example: "Revenue increased this quarter.", pronunciation: "ˈrevəˌnuː", category: toeicCategory),
            Flashcard(word: "Expense", meaning: "経費", example: "Business expenses are tax deductible.", pronunciation: "ɪkˈspens", category: toeicCategory),
            // 人事・採用
            Flashcard(word: "Employee", meaning: "従業員", example: "We hired a new employee.", pronunciation: "ɪmˈplɔɪi", category: toeicCategory),
            Flashcard(word: "Interview", meaning: "面接", example: "I have a job interview tomorrow.", pronunciation: "ˈɪntərvjuː", category: toeicCategory),
            Flashcard(word: "Resume", meaning: "履歴書", example: "Please submit your resume.", pronunciation: "rɪˈzuːmeɪ", category: toeicCategory),
            Flashcard(word: "Applicant", meaning: "応募者", example: "We have many qualified applicants.", pronunciation: "ˈæplɪkənt", category: toeicCategory),
            Flashcard(word: "Position", meaning: "職位", example: "This position requires experience.", pronunciation: "pəˈzɪʃən", category: toeicCategory),
            // 一般ビジネス
            Flashcard(word: "Client", meaning: "顧客", example: "Our client is satisfied.", pronunciation: "ˈklaɪənt", category: toeicCategory),
            Flashcard(word: "Customer", meaning: "お客様", example: "Customer service is important.", pronunciation: "ˈkʌstəmər", category: toeicCategory),
            Flashcard(word: "Contract", meaning: "契約", example: "Please sign the contract.", pronunciation: "ˈkɒntrækt", category: toeicCategory),
            Flashcard(word: "Document", meaning: "書類", example: "I need to review this document.", pronunciation: "ˈdɒkjəmənt", category: toeicCategory),
            Flashcard(word: "Report", meaning: "報告書", example: "The report is due Friday.", pronunciation: "rɪˈpɔːrt", category: toeicCategory),
            // 高頻出語彙
            Flashcard(word: "Available", meaning: "利用可能な", example: "Is this time slot available?", pronunciation: "əˈveɪləbəl", category: toeicCategory),
            Flashcard(word: "Confirm", meaning: "確認する", example: "Please confirm your attendance.", pronunciation: "kənˈfɜːrm", category: toeicCategory),
            Flashcard(word: "Recommend", meaning: "推薦する", example: "I recommend this restaurant.", pronunciation: "ˌrekəˈmend", category: toeicCategory),
            Flashcard(word: "Improve", meaning: "改善する", example: "We need to improve our service.", pronunciation: "ɪmˈpruːv", category: toeicCategory),
            Flashcard(word: "Efficient", meaning: "効率的な", example: "This method is very efficient.", pronunciation: "ɪˈfɪʃənt", category: toeicCategory)
        ]
        
        for flashcard in toeicFlashcards {
            modelContext.insert(flashcard)
            toeicCategory.flashcards.append(flashcard)
        }
        
        // ビジネス英語カテゴリ
        let businessCategory = Category(name: "ビジネス英語", icon: "briefcase.fill", color: "AsaCoffeeBrown")
        modelContext.insert(businessCategory)
        
        let businessFlashcards = [
            // メール・コミュニケーション
            Flashcard(word: "Regarding", meaning: "〜に関して", example: "Regarding your email...", pronunciation: "rɪˈɡɑːrdɪŋ", category: businessCategory),
            Flashcard(word: "Attached", meaning: "添付された", example: "Please find attached the document.", pronunciation: "əˈtætʃt", category: businessCategory),
            Flashcard(word: "Reply", meaning: "返信", example: "I'll reply to your email soon.", pronunciation: "rɪˈplaɪ", category: businessCategory),
            Flashcard(word: "Forward", meaning: "転送する", example: "Please forward this to the team.", pronunciation: "ˈfɔːrwərd", category: businessCategory),
            Flashcard(word: "Update", meaning: "更新・報告", example: "Here's an update on the project.", pronunciation: "ʌpˈdeɪt", category: businessCategory),
            // プレゼンテーション
            Flashcard(word: "Presentation", meaning: "プレゼンテーション", example: "My presentation is at 3 PM.", pronunciation: "ˌprezənˈteɪʃən", category: businessCategory),
            Flashcard(word: "Slide", meaning: "スライド", example: "Move to the next slide.", pronunciation: "slaɪd", category: businessCategory),
            Flashcard(word: "Audience", meaning: "聴衆", example: "The audience asked good questions.", pronunciation: "ˈɔːdiəns", category: businessCategory),
            Flashcard(word: "Summary", meaning: "要約", example: "In summary, we need to act now.", pronunciation: "ˈsʌməri", category: businessCategory),
            Flashcard(word: "Proposal", meaning: "提案", example: "I have a proposal for you.", pronunciation: "prəˈpoʊzəl", category: businessCategory),
            // 交渉・決定
            Flashcard(word: "Negotiate", meaning: "交渉する", example: "We need to negotiate the price.", pronunciation: "nɪˈɡoʊʃieɪt", category: businessCategory),
            Flashcard(word: "Agreement", meaning: "合意", example: "We reached an agreement.", pronunciation: "əˈɡriːmənt", category: businessCategory),
            Flashcard(word: "Decision", meaning: "決定", example: "We need to make a decision.", pronunciation: "dɪˈsɪʒən", category: businessCategory),
            Flashcard(word: "Deadline", meaning: "締切", example: "The deadline is next Friday.", pronunciation: "ˈdedlaɪn", category: businessCategory),
            Flashcard(word: "Priority", meaning: "優先事項", example: "This is our top priority.", pronunciation: "praɪˈɔːrəti", category: businessCategory),
            // チームワーク・協力
            Flashcard(word: "Collaborate", meaning: "協力する", example: "We need to collaborate on this.", pronunciation: "kəˈlæbəreɪt", category: businessCategory),
            Flashcard(word: "Teamwork", meaning: "チームワーク", example: "Good teamwork is essential.", pronunciation: "ˈtiːmwərk", category: businessCategory),
            Flashcard(word: "Colleague", meaning: "同僚", example: "My colleague will help you.", pronunciation: "ˈkɒliːɡ", category: businessCategory),
            Flashcard(word: "Support", meaning: "サポート", example: "I need your support on this.", pronunciation: "səˈpɔːrt", category: businessCategory),
            Flashcard(word: "Feedback", meaning: "フィードバック", example: "Please give me your feedback.", pronunciation: "ˈfiːdbæk", category: businessCategory),
            // 問題解決・改善
            Flashcard(word: "Solution", meaning: "解決策", example: "We found a good solution.", pronunciation: "səˈluːʃən", category: businessCategory),
            Flashcard(word: "Challenge", meaning: "課題・挑戦", example: "This is a big challenge.", pronunciation: "ˈtʃælɪndʒ", category: businessCategory),
            Flashcard(word: "Opportunity", meaning: "機会", example: "This is a great opportunity.", pronunciation: "ˌɑːpərˈtuːnəti", category: businessCategory),
            Flashcard(word: "Achievement", meaning: "達成・成果", example: "This is a great achievement.", pronunciation: "əˈtʃiːvmənt", category: businessCategory),
            Flashcard(word: "Strategy", meaning: "戦略", example: "Our strategy is working well.", pronunciation: "ˈstrætədʒi", category: businessCategory)
        ]
        
        for flashcard in businessFlashcards {
            modelContext.insert(flashcard)
            businessCategory.flashcards.append(flashcard)
        }
        
        // 日常英会話カテゴリ
        let conversationCategory = Category(name: "日常英会話", icon: "bubble.left.and.bubble.right.fill", color: "AsaSoftCream")
        modelContext.insert(conversationCategory)
        
        let conversationFlashcards = [
            // 朝の挨拶・日常
            Flashcard(word: "Good morning", meaning: "おはようございます", example: "Good morning! How are you?", pronunciation: "ɡʊd ˈmɔːrnɪŋ", category: conversationCategory),
            Flashcard(word: "How's it going", meaning: "調子はどう", example: "Hey! How's it going today?", pronunciation: "haʊz ɪt ˈɡoʊɪŋ", category: conversationCategory),
            Flashcard(word: "I'm fine", meaning: "元気です", example: "Thanks for asking, I'm fine.", pronunciation: "aɪm faɪn", category: conversationCategory),
            Flashcard(word: "See you later", meaning: "また後で", example: "I have to go. See you later!", pronunciation: "siː juː ˈleɪtər", category: conversationCategory),
            Flashcard(word: "Take care", meaning: "気をつけて", example: "Take care on your way home.", pronunciation: "teɪk ker", category: conversationCategory),
            // 家族・子育て関連
            Flashcard(word: "How was school", meaning: "学校はどうだった", example: "How was school today, honey?", pronunciation: "haʊ wʌz skuːl", category: conversationCategory),
            Flashcard(word: "Did you have fun", meaning: "楽しかった？", example: "Did you have fun at the park?", pronunciation: "dɪd juː hæv fʌn", category: conversationCategory),
            Flashcard(word: "Time for bed", meaning: "寝る時間", example: "It's time for bed, kids.", pronunciation: "taɪm fər bed", category: conversationCategory),
            Flashcard(word: "Sweet dreams", meaning: "いい夢を", example: "Good night, sweet dreams!", pronunciation: "swiːt driːmz", category: conversationCategory),
            Flashcard(word: "I love you", meaning: "愛してるよ", example: "I love you, my family.", pronunciation: "aɪ lʌv juː", category: conversationCategory),
            // 食事・生活
            Flashcard(word: "What's for dinner", meaning: "夕食は何？", example: "What's for dinner tonight?", pronunciation: "wʌts fər ˈdɪnər", category: conversationCategory),
            Flashcard(word: "It looks delicious", meaning: "美味しそう", example: "Wow, it looks delicious!", pronunciation: "ɪt lʊks dɪˈlɪʃəs", category: conversationCategory),
            Flashcard(word: "I'm hungry", meaning: "お腹が空いた", example: "I'm getting hungry now.", pronunciation: "aɪm ˈhʌŋɡri", category: conversationCategory),
            Flashcard(word: "Let's eat", meaning: "食べましょう", example: "The food is ready. Let's eat!", pronunciation: "lets iːt", category: conversationCategory),
            Flashcard(word: "Thank you for the meal", meaning: "ご馳走さまでした", example: "Thank you for the meal, honey.", pronunciation: "θæŋk juː fər ðə miːl", category: conversationCategory),
            // 週末・レジャー
            Flashcard(word: "What are you doing", meaning: "何してるの？", example: "What are you doing this weekend?", pronunciation: "wʌt ər juː ˈduːɪŋ", category: conversationCategory),
            Flashcard(word: "Let's go out", meaning: "出かけよう", example: "It's a nice day. Let's go out!", pronunciation: "lets ɡoʊ aʊt", category: conversationCategory),
            Flashcard(word: "How about", meaning: "〜はどう？", example: "How about going to the park?", pronunciation: "haʊ əˈbaʊt", category: conversationCategory),
            Flashcard(word: "That sounds good", meaning: "それいいね", example: "That sounds good to me.", pronunciation: "ðæt saʊndz ɡʊd", category: conversationCategory),
            Flashcard(word: "I had a great time", meaning: "楽しかった", example: "I had a great time today.", pronunciation: "aɪ hæd ə ɡreɪt taɪm", category: conversationCategory),
            // 感情・感想
            Flashcard(word: "I'm excited", meaning: "ワクワクする", example: "I'm excited about tomorrow.", pronunciation: "aɪm ɪkˈsaɪtɪd", category: conversationCategory),
            Flashcard(word: "That's amazing", meaning: "すごいね", example: "That's amazing! Congratulations!", pronunciation: "ðæts əˈmeɪzɪŋ", category: conversationCategory),
            Flashcard(word: "I'm proud of you", meaning: "君を誇りに思う", example: "I'm proud of you, son.", pronunciation: "aɪm praʊd ʌv juː", category: conversationCategory),
            Flashcard(word: "Don't worry", meaning: "心配しないで", example: "Don't worry, everything will be fine.", pronunciation: "doʊnt ˈwɜːri", category: conversationCategory),
            Flashcard(word: "You can do it", meaning: "君ならできる", example: "You can do it! I believe in you.", pronunciation: "juː kæn duː ɪt", category: conversationCategory),
            // 一般会話
            Flashcard(word: "What do you think", meaning: "どう思う？", example: "What do you think about this idea?", pronunciation: "wʌt duː juː θɪŋk", category: conversationCategory),
            Flashcard(word: "I agree", meaning: "同感です", example: "I agree with your opinion.", pronunciation: "aɪ əˈɡriː", category: conversationCategory),
            Flashcard(word: "That makes sense", meaning: "なるほど", example: "That makes sense to me.", pronunciation: "ðæt meɪks sens", category: conversationCategory),
            Flashcard(word: "Excuse me", meaning: "すみません", example: "Excuse me, could you help me?", pronunciation: "ɪkˈskjuːz miː", category: conversationCategory),
            Flashcard(word: "You're welcome", meaning: "どういたしまして", example: "You're welcome, anytime!", pronunciation: "jʊər ˈwelkəm", category: conversationCategory)
        ]
        
        for flashcard in conversationFlashcards {
            modelContext.insert(flashcard)
            conversationCategory.flashcards.append(flashcard)
        }
        
        // 数学・科学用語カテゴリ
        let scienceCategory = Category(name: "数学・科学用語", icon: "function", color: "AsaMutedSage")
        modelContext.insert(scienceCategory)
        
        let scienceFlashcards = [
            // 基本数学
            Flashcard(word: "Number", meaning: "数", example: "What's your favorite number?", pronunciation: "ˈnʌmbər", category: scienceCategory),
            Flashcard(word: "Addition", meaning: "足し算", example: "2 plus 3 equals 5 in addition.", pronunciation: "əˈdɪʃən", category: scienceCategory),
            Flashcard(word: "Subtraction", meaning: "引き算", example: "5 minus 2 equals 3 in subtraction.", pronunciation: "səbˈtrækʃən", category: scienceCategory),
            Flashcard(word: "Multiplication", meaning: "掛け算", example: "3 times 4 equals 12 in multiplication.", pronunciation: "ˌmʌltəpləˈkeɪʃən", category: scienceCategory),
            Flashcard(word: "Division", meaning: "割り算", example: "8 divided by 2 equals 4 in division.", pronunciation: "dɪˈvɪʒən", category: scienceCategory),
            // 図形・幾何
            Flashcard(word: "Circle", meaning: "円", example: "Draw a perfect circle.", pronunciation: "ˈsɜːrkəl", category: scienceCategory),
            Flashcard(word: "Triangle", meaning: "三角形", example: "A triangle has three sides.", pronunciation: "ˈtraɪæŋɡəl", category: scienceCategory),
            Flashcard(word: "Square", meaning: "正方形", example: "A square has four equal sides.", pronunciation: "skwer", category: scienceCategory),
            Flashcard(word: "Rectangle", meaning: "長方形", example: "This is a rectangle shape.", pronunciation: "ˈrektæŋɡəl", category: scienceCategory),
            // 自然科学
            Flashcard(word: "Gravity", meaning: "重力", example: "Gravity pulls things down.", pronunciation: "ˈɡrævəti", category: scienceCategory),
            Flashcard(word: "Energy", meaning: "エネルギー", example: "Solar panels convert sunlight to energy.", pronunciation: "ˈenərdʒi", category: scienceCategory),
            Flashcard(word: "Temperature", meaning: "温度", example: "The temperature is 25 degrees today.", pronunciation: "ˈtemprətʃər", category: scienceCategory),
            Flashcard(word: "Experiment", meaning: "実験", example: "Let's do a science experiment.", pronunciation: "ɪkˈsperəmənt", category: scienceCategory),
            // 化学・物理
            Flashcard(word: "Molecule", meaning: "分子", example: "Water is made of H2O molecules.", pronunciation: "ˈmɒlɪkjuːl", category: scienceCategory),
            Flashcard(word: "Atom", meaning: "原子", example: "Everything is made of tiny atoms.", pronunciation: "ˈætəm", category: scienceCategory),
            Flashcard(word: "Force", meaning: "力", example: "You need force to push the door.", pronunciation: "fɔːrs", category: scienceCategory),
            Flashcard(word: "Motion", meaning: "運動", example: "The ball is in motion.", pronunciation: "ˈmoʊʃən", category: scienceCategory),
            // 測定・単位
            Flashcard(word: "Measurement", meaning: "測定", example: "Accurate measurement is important.", pronunciation: "ˈmeʒərmənt", category: scienceCategory),
            Flashcard(word: "Length", meaning: "長さ", example: "What's the length of this table?", pronunciation: "leŋθ", category: scienceCategory),
            Flashcard(word: "Weight", meaning: "重さ", example: "The weight of the apple is 200g.", pronunciation: "weɪt", category: scienceCategory)
        ]
        
        for flashcard in scienceFlashcards {
            modelContext.insert(flashcard)
            scienceCategory.flashcards.append(flashcard)
        }
        
        // IT・テック用語カテゴリ
        let techCategory = Category(name: "IT・テック用語", icon: "desktopcomputer", color: "AsaDarkSlate")
        modelContext.insert(techCategory)
        
        let techFlashcards = [
            // AI・機械学習
            Flashcard(word: "Artificial Intelligence", meaning: "人工知能", example: "AI will change how we work.", pronunciation: "ˌɑːrtɪˈfɪʃəl ɪnˈtelɪdʒəns", category: techCategory),
            Flashcard(word: "Machine Learning", meaning: "機械学習", example: "Machine learning improves over time.", pronunciation: "məˈʃiːn ˈlɜːrnɪŋ", category: techCategory),
            Flashcard(word: "Algorithm", meaning: "アルゴリズム", example: "This algorithm is very efficient.", pronunciation: "ˈælɡərɪðəm", category: techCategory),
            Flashcard(word: "Data Science", meaning: "データサイエンス", example: "Data science helps make decisions.", pronunciation: "ˈdeɪtə ˈsaɪəns", category: techCategory),
            // クラウド・インフラ
            Flashcard(word: "Cloud Computing", meaning: "クラウドコンピューティング", example: "We use cloud computing for storage.", pronunciation: "klaʊd kəmˈpjuːtɪŋ", category: techCategory),
            Flashcard(word: "Server", meaning: "サーバー", example: "The server is running smoothly.", pronunciation: "ˈsɜːrvər", category: techCategory),
            Flashcard(word: "Database", meaning: "データベース", example: "All data is stored in the database.", pronunciation: "ˈdeɪtəbeɪs", category: techCategory),
            Flashcard(word: "API", meaning: "API", example: "This API connects two systems.", pronunciation: "eɪ piː aɪ", category: techCategory),
            Flashcard(word: "Microservices", meaning: "マイクロサービス", example: "We use microservices architecture.", pronunciation: "ˈmaɪkroʊsɜːrvəsəz", category: techCategory),
            // セキュリティ
            Flashcard(word: "Cybersecurity", meaning: "サイバーセキュリティ", example: "Cybersecurity is very important.", pronunciation: "ˈsaɪbərsɪˈkjʊrəti", category: techCategory),
            Flashcard(word: "Encryption", meaning: "暗号化", example: "Data encryption protects information.", pronunciation: "ɪnˈkrɪpʃən", category: techCategory),
            Flashcard(word: "Authentication", meaning: "認証", example: "Two-factor authentication is secure.", pronunciation: "ɔːˌθentɪˈkeɪʃən", category: techCategory),
            Flashcard(word: "Firewall", meaning: "ファイアウォール", example: "The firewall blocks threats.", pronunciation: "ˈfaɪərwɔːl", category: techCategory),
            // Web・モバイル技術
            Flashcard(word: "Responsive Design", meaning: "レスポンシブデザイン", example: "Responsive design works on all devices.", pronunciation: "rɪˈspɑːnsɪv dɪˈzaɪn", category: techCategory),
            Flashcard(word: "User Interface", meaning: "ユーザーインターフェース", example: "The user interface is intuitive.", pronunciation: "ˈjuːzər ˈɪntərfeɪs", category: techCategory),
            Flashcard(word: "User Experience", meaning: "ユーザーエクスペリエンス", example: "Good user experience increases satisfaction.", pronunciation: "ˈjuːzər ɪkˈspɪriəns", category: techCategory),
            Flashcard(word: "Backend", meaning: "バックエンド", example: "The backend handles data processing.", pronunciation: "ˈbækend", category: techCategory),
            Flashcard(word: "Frontend", meaning: "フロントエンド", example: "The frontend is what users see.", pronunciation: "ˈfrʌntend", category: techCategory),
            // 開発手法・ツール
            Flashcard(word: "Agile", meaning: "アジャイル", example: "We use agile development methods.", pronunciation: "ˈædʒəl", category: techCategory),
            Flashcard(word: "DevOps", meaning: "DevOps", example: "DevOps improves deployment speed.", pronunciation: "ˈdevɑːps", category: techCategory),
            Flashcard(word: "Version Control", meaning: "バージョン管理", example: "Git is for version control.", pronunciation: "ˈvɜːrʒən kənˈtroʊl", category: techCategory),
            Flashcard(word: "Continuous Integration", meaning: "継続的インテグレーション", example: "CI helps catch bugs early.", pronunciation: "kənˈtɪnjuəs ˌɪntɪˈɡreɪʃən", category: techCategory),
            // 新技術トレンド
            Flashcard(word: "Blockchain", meaning: "ブロックチェーン", example: "Blockchain ensures data integrity.", pronunciation: "ˈblɑːktʃeɪn", category: techCategory),
            Flashcard(word: "Internet of Things", meaning: "IoT", example: "IoT connects everyday devices.", pronunciation: "ˈɪntərnet ʌv θɪŋz", category: techCategory),
            Flashcard(word: "Virtual Reality", meaning: "バーチャルリアリティ", example: "VR creates immersive experiences.", pronunciation: "ˈvɜːrtʃuəl riˈæləti", category: techCategory)
        ]
        
        for flashcard in techFlashcards {
            modelContext.insert(flashcard)
            techCategory.flashcards.append(flashcard)
        }
        
        // 家族・子育て用語カテゴリ
        let parentingCategory = Category(name: "家族・子育て用語", icon: "figure.2.and.child.holdinghands", color: "AsaMocha")
        modelContext.insert(parentingCategory)
        
        let parentingFlashcards = [
            // 家族構成
            Flashcard(word: "Father", meaning: "お父さん", example: "I am a father of two children.", pronunciation: "ˈfɑːðər", category: parentingCategory),
            Flashcard(word: "Mother", meaning: "お母さん", example: "My mother helps with childcare.", pronunciation: "ˈmʌðər", category: parentingCategory),
            Flashcard(word: "Parent", meaning: "親", example: "Being a parent is rewarding.", pronunciation: "ˈperənt", category: parentingCategory),
            Flashcard(word: "Children", meaning: "子どもたち", example: "Our children are growing fast.", pronunciation: "ˈtʃɪldrən", category: parentingCategory),
            Flashcard(word: "Siblings", meaning: "兄弟姉妹", example: "The siblings play together well.", pronunciation: "ˈsɪblɪŋz", category: parentingCategory),
            // 子育て活動
            Flashcard(word: "Parenting", meaning: "子育て", example: "Parenting requires patience.", pronunciation: "ˈperəntɪŋ", category: parentingCategory),
            Flashcard(word: "Bedtime story", meaning: "寝る前の読み聞かせ", example: "I read a bedtime story every night.", pronunciation: "ˈbedtaɪm ˈstɔːri", category: parentingCategory),
            Flashcard(word: "Playground", meaning: "遊び場", example: "Let's go to the playground!", pronunciation: "ˈpleɪɡraʊnd", category: parentingCategory),
            Flashcard(word: "Homework", meaning: "宿題", example: "Help your child with homework.", pronunciation: "ˈhoʊmwərk", category: parentingCategory),
            Flashcard(word: "School pickup", meaning: "お迎え", example: "It's time for school pickup.", pronunciation: "skuːl ˈpɪkʌp", category: parentingCategory),
            // 朝活・ルーティン
            Flashcard(word: "Morning routine", meaning: "朝のルーティン", example: "Our morning routine starts at 6 AM.", pronunciation: "ˈmɔːrnɪŋ ruːˈtiːn", category: parentingCategory),
            Flashcard(word: "Early bird", meaning: "早起きの人", example: "I'm an early bird parent.", pronunciation: "ˈɜːrli bɜːrd", category: parentingCategory),
            Flashcard(word: "Quality time", meaning: "家族の時間", example: "We spend quality time together.", pronunciation: "ˈkwɑːləti taɪm", category: parentingCategory),
            Flashcard(word: "Work-life balance", meaning: "仕事と家庭の両立", example: "Good work-life balance is important.", pronunciation: "wərk laɪf ˈbæləns", category: parentingCategory),
            // 感情・しつけ
            Flashcard(word: "Patience", meaning: "忍耐", example: "Parenting teaches you patience.", pronunciation: "ˈpeɪʃəns", category: parentingCategory),
            Flashcard(word: "Encouragement", meaning: "励まし", example: "Children need encouragement to grow.", pronunciation: "ɪnˈkɜːrɪdʒmənt", category: parentingCategory),
            Flashcard(word: "Discipline", meaning: "しつけ", example: "Consistent discipline helps children.", pronunciation: "ˈdɪsəplən", category: parentingCategory),
            Flashcard(word: "Praise", meaning: "褒める", example: "Remember to praise good behavior.", pronunciation: "preɪz", category: parentingCategory),
            // 成長・発達
            Flashcard(word: "Milestone", meaning: "発達の節目", example: "Walking is an important milestone.", pronunciation: "ˈmaɪlstoʊn", category: parentingCategory),
            Flashcard(word: "Growing up", meaning: "成長", example: "Children are growing up so fast.", pronunciation: "ˈɡroʊɪŋ ʌp", category: parentingCategory)
        ]
        
        for flashcard in parentingFlashcards {
            modelContext.insert(flashcard)
            parentingCategory.flashcards.append(flashcard)
        }
        
        // 句動詞カテゴリ（Phrasal Verbs）
        let phrasalCategory = Category(name: "句動詞", icon: "arrow.triangle.2.circlepath", color: "AsaDarkSlate")
        modelContext.insert(phrasalCategory)
        
        let phrasalFlashcards = [
            Flashcard(word: "pick up", meaning: "拾う／迎えに行く", example: "I'll pick up the kids at 5.", category: phrasalCategory),
            Flashcard(word: "set up", meaning: "準備する／設置する", example: "We need to set up the projector.", category: phrasalCategory),
            Flashcard(word: "take off", meaning: "離陸する／脱ぐ", example: "The plane will take off soon.", category: phrasalCategory),
            Flashcard(word: "put off", meaning: "延期する", example: "Let's put off the meeting to tomorrow.", category: phrasalCategory),
            Flashcard(word: "turn on", meaning: "電源を入れる", example: "Please turn on the lights.", category: phrasalCategory),
            Flashcard(word: "turn off", meaning: "電源を切る", example: "Don't forget to turn off the AC.", category: phrasalCategory),
            Flashcard(word: "get along", meaning: "仲良くやる", example: "They get along very well.", category: phrasalCategory),
            Flashcard(word: "look up", meaning: "調べる", example: "I'll look it up online.", category: phrasalCategory),
            Flashcard(word: "look after", meaning: "世話をする", example: "Can you look after my dog?", category: phrasalCategory),
            Flashcard(word: "run into", meaning: "偶然出くわす", example: "I ran into an old friend.", category: phrasalCategory),
            Flashcard(word: "carry on", meaning: "続ける", example: "Please carry on with your work.", category: phrasalCategory),
            Flashcard(word: "bring up", meaning: "話題に出す／育てる", example: "She brought up an interesting point.", category: phrasalCategory),
            Flashcard(word: "come across", meaning: "偶然見つける", example: "I came across a great article.", category: phrasalCategory),
            Flashcard(word: "figure out", meaning: "解決する／理解する", example: "We need to figure out a solution.", category: phrasalCategory),
            Flashcard(word: "hand in", meaning: "提出する", example: "Please hand in your report by noon.", category: phrasalCategory),
            Flashcard(word: "hang out", meaning: "のんびり過ごす", example: "Let's hang out this weekend.", category: phrasalCategory),
            Flashcard(word: "keep up", meaning: "ついていく／維持する", example: "Keep up the good work!", category: phrasalCategory),
            Flashcard(word: "pay off", meaning: "成果が出る／完済する", example: "Your effort will pay off.", category: phrasalCategory),
            Flashcard(word: "point out", meaning: "指摘する", example: "Thanks for pointing that out.", category: phrasalCategory),
            Flashcard(word: "work out", meaning: "うまくいく／解く／運動する", example: "It will work out in the end.", category: phrasalCategory)
        ]
        
        for flashcard in phrasalFlashcards {
            modelContext.insert(flashcard)
            phrasalCategory.flashcards.append(flashcard)
        }
        
        // 英熟語カテゴリ（Idioms）
        let idiomCategory = Category(name: "英熟語", icon: "quote.bubble.fill", color: "AsaMutedSage")
        modelContext.insert(idiomCategory)
        
        let idiomFlashcards = [
            Flashcard(word: "a piece of cake", meaning: "とても簡単", example: "The test was a piece of cake.", category: idiomCategory),
            Flashcard(word: "break a leg", meaning: "健闘を祈る", example: "Good luck! Break a leg.", category: idiomCategory),
            Flashcard(word: "hit the books", meaning: "勉強する", example: "I have to hit the books tonight.", category: idiomCategory),
            Flashcard(word: "under the weather", meaning: "体調が悪い", example: "I'm feeling under the weather.", category: idiomCategory),
            Flashcard(word: "once in a blue moon", meaning: "ごくたまに", example: "He visits once in a blue moon.", category: idiomCategory),
            Flashcard(word: "cost an arm and a leg", meaning: "とても高い", example: "The repair cost an arm and a leg.", category: idiomCategory),
            Flashcard(word: "on the same page", meaning: "認識が一致して", example: "Now we're on the same page.", category: idiomCategory),
            Flashcard(word: "out of the blue", meaning: "突然", example: "She called me out of the blue.", category: idiomCategory),
            Flashcard(word: "rule of thumb", meaning: "経験則", example: "As a rule of thumb, start small.", category: idiomCategory),
            Flashcard(word: "back to square one", meaning: "振り出しに戻る", example: "We are back to square one.", category: idiomCategory),
            Flashcard(word: "call it a day", meaning: "切り上げる", example: "Let's call it a day.", category: idiomCategory),
            Flashcard(word: "get cold feet", meaning: "尻込みする", example: "He got cold feet at the last minute.", category: idiomCategory),
            Flashcard(word: "on cloud nine", meaning: "有頂天で", example: "She was on cloud nine.", category: idiomCategory),
            Flashcard(word: "the ball is in your court", meaning: "次はあなたの番", example: "The ball is in your court now.", category: idiomCategory),
            Flashcard(word: "in hot water", meaning: "困った立場", example: "He's in hot water with his boss.", category: idiomCategory),
            Flashcard(word: "cut corners", meaning: "手を抜く", example: "Don't cut corners on safety.", category: idiomCategory),
            Flashcard(word: "face the music", meaning: "現実を受け止める", example: "It's time to face the music.", category: idiomCategory),
            Flashcard(word: "let the cat out of the bag", meaning: "秘密を漏らす", example: "Who let the cat out of the bag?", category: idiomCategory),
            Flashcard(word: "on the fence", meaning: "決めかねて", example: "I'm on the fence about it.", category: idiomCategory),
            Flashcard(word: "up in the air", meaning: "未定で", example: "The plan is still up in the air.", category: idiomCategory)
        ]
        
        for flashcard in idiomFlashcards {
            modelContext.insert(flashcard)
            idiomCategory.flashcards.append(flashcard)
        }
        
        // 旅行英語カテゴリ
        let travelCategory = Category(name: "旅行英語", icon: "airplane", color: "AsaCoffeeBrown")
        modelContext.insert(travelCategory)
        
        let travelFlashcards = [
            Flashcard(word: "boarding pass", meaning: "搭乗券", example: "Please show your boarding pass.", category: travelCategory),
            Flashcard(word: "check-in", meaning: "チェックイン", example: "What time is check-in?", category: travelCategory),
            Flashcard(word: "baggage claim", meaning: "手荷物受取所", example: "The baggage claim is on the first floor.", category: travelCategory),
            Flashcard(word: "gate", meaning: "搭乗口", example: "Your gate is B12.", category: travelCategory),
            Flashcard(word: "connecting flight", meaning: "乗り継ぎ便", example: "We have a connecting flight in Dubai.", category: travelCategory),
            Flashcard(word: "aisle seat", meaning: "通路側の席", example: "I'd like an aisle seat.", category: travelCategory),
            Flashcard(word: "window seat", meaning: "窓側の席", example: "Is a window seat available?", category: travelCategory),
            Flashcard(word: "carry-on", meaning: "機内持ち込み手荷物", example: "This is my carry-on.", category: travelCategory),
            Flashcard(word: "customs", meaning: "税関", example: "Do I need to go through customs?", category: travelCategory),
            Flashcard(word: "immigration", meaning: "入国審査", example: "Immigration took a while.", category: travelCategory),
            Flashcard(word: "reservation", meaning: "予約", example: "I have a reservation under Tanaka.", category: travelCategory),
            Flashcard(word: "confirmation", meaning: "予約確認", example: "Could you send the confirmation email?", category: travelCategory),
            Flashcard(word: "itinerary", meaning: "旅程", example: "Here's our itinerary for the trip.", category: travelCategory),
            Flashcard(word: "sightseeing", meaning: "観光", example: "We're going sightseeing tomorrow.", category: travelCategory),
            Flashcard(word: "attraction", meaning: "名所", example: "This is a popular attraction.", category: travelCategory),
            Flashcard(word: "admission fee", meaning: "入場料", example: "What's the admission fee?", category: travelCategory),
            Flashcard(word: "discount", meaning: "割引", example: "Is there a student discount?", category: travelCategory),
            Flashcard(word: "currency exchange", meaning: "両替", example: "Where is the currency exchange?", category: travelCategory),
            Flashcard(word: "travel insurance", meaning: "旅行保険", example: "Do you have travel insurance?", category: travelCategory),
            Flashcard(word: "souvenir", meaning: "お土産", example: "Let's buy some souvenirs.", category: travelCategory)
        ]
        
        for flashcard in travelFlashcards {
            modelContext.insert(flashcard)
            travelCategory.flashcards.append(flashcard)
        }
        
        // 医療・健康英語カテゴリ
        let healthCategory = Category(name: "医療・健康英語", icon: "heart.fill", color: "AsaMocha")
        modelContext.insert(healthCategory)
        
        let healthFlashcards = [
            Flashcard(word: "symptom", meaning: "症状", example: "Do you have any symptoms?", category: healthCategory),
            Flashcard(word: "diagnosis", meaning: "診断", example: "We need a proper diagnosis.", category: healthCategory),
            Flashcard(word: "prescription", meaning: "処方箋", example: "This is your prescription.", category: healthCategory),
            Flashcard(word: "dosage", meaning: "用量", example: "Check the dosage on the label.", category: healthCategory),
            Flashcard(word: "side effects", meaning: "副作用", example: "Are there any side effects?", category: healthCategory),
            Flashcard(word: "appointment", meaning: "予約", example: "I'd like to make an appointment.", category: healthCategory),
            Flashcard(word: "checkup", meaning: "健康診断", example: "It's time for a checkup.", category: healthCategory),
            Flashcard(word: "fever", meaning: "熱", example: "I have a high fever.", category: healthCategory),
            Flashcard(word: "cough", meaning: "咳", example: "This cough won't go away.", category: healthCategory),
            Flashcard(word: "headache", meaning: "頭痛", example: "I have a headache.", category: healthCategory),
            Flashcard(word: "allergy", meaning: "アレルギー", example: "Do you have any allergies?", category: healthCategory),
            Flashcard(word: "vaccine", meaning: "ワクチン", example: "I got a flu vaccine.", category: healthCategory),
            Flashcard(word: "blood pressure", meaning: "血圧", example: "Your blood pressure is normal.", category: healthCategory),
            Flashcard(word: "heart rate", meaning: "心拍数", example: "Measure your heart rate.", category: healthCategory),
            Flashcard(word: "emergency", meaning: "救急", example: "Call 911 in an emergency.", category: healthCategory),
            Flashcard(word: "first aid", meaning: "応急手当", example: "We need a first-aid kit.", category: healthCategory),
            Flashcard(word: "pharmacy", meaning: "薬局", example: "Is there a pharmacy nearby?", category: healthCategory),
            Flashcard(word: "insurance card", meaning: "保険証", example: "Please show your insurance card.", category: healthCategory),
            Flashcard(word: "referral", meaning: "紹介状", example: "You need a referral to see a specialist.", category: healthCategory),
            Flashcard(word: "specialist", meaning: "専門医", example: "I'll refer you to a specialist.", category: healthCategory)
        ]
        
        for flashcard in healthFlashcards {
            modelContext.insert(flashcard)
            healthCategory.flashcards.append(flashcard)
        }
        
        // 学術英語（AWL Sublist 1）
        let awlCategory = Category(name: "学術英語（AWL）", icon: "book.closed.fill", color: "AsaSoftCream")
        modelContext.insert(awlCategory)
        
        let awlFlashcards = [
            Flashcard(word: "analyze", meaning: "分析する", example: "We need to analyze the data.", category: awlCategory),
            Flashcard(word: "approach", meaning: "取り組み／取り組む", example: "This is a practical approach.", category: awlCategory),
            Flashcard(word: "area", meaning: "分野／領域", example: "This area needs more research.", category: awlCategory),
            Flashcard(word: "assess", meaning: "評価する", example: "We will assess the risks.", category: awlCategory),
            Flashcard(word: "assume", meaning: "仮定する", example: "Don't assume without evidence.", category: awlCategory),
            Flashcard(word: "authority", meaning: "権威／権限", example: "Who has the authority to approve?", category: awlCategory),
            Flashcard(word: "available", meaning: "利用可能な", example: "The data is not available.", category: awlCategory),
            Flashcard(word: "benefit", meaning: "利益／恩恵", example: "This policy has clear benefits.", category: awlCategory),
            Flashcard(word: "concept", meaning: "概念", example: "The key concept is simple.", category: awlCategory),
            Flashcard(word: "consistent", meaning: "一貫した", example: "Results are consistent across studies.", category: awlCategory),
            Flashcard(word: "create", meaning: "作成する", example: "Create a new dataset.", category: awlCategory),
            Flashcard(word: "data", meaning: "データ", example: "The data supports our claim.", category: awlCategory),
            Flashcard(word: "definition", meaning: "定義", example: "We need a clear definition.", category: awlCategory),
            Flashcard(word: "economy", meaning: "経済", example: "The global economy is changing.", category: awlCategory),
            Flashcard(word: "environment", meaning: "環境", example: "Protecting the environment is vital.", category: awlCategory),
            Flashcard(word: "establish", meaning: "確立する／設立する", example: "We will establish a baseline.", category: awlCategory),
            Flashcard(word: "estimate", meaning: "見積もる／推定", example: "Please estimate the cost.", category: awlCategory),
            Flashcard(word: "evidence", meaning: "証拠", example: "There is strong evidence.", category: awlCategory),
            Flashcard(word: "factor", meaning: "要因", example: "Many factors affect the result.", category: awlCategory),
            Flashcard(word: "finance", meaning: "財務／資金", example: "We need to secure finance.", category: awlCategory)
        ]
        
        for flashcard in awlFlashcards {
            modelContext.insert(flashcard)
            awlCategory.flashcards.append(flashcard)
        }
        
        // データを保存
        do {
            try modelContext.save()
        } catch {
            print("サンプルデータの作成に失敗しました: \(error)")
        }
    }

    // 既存データを壊さず、不足分だけを追加するアップグレード挿入
    private func upgradeSampleDataIfNeeded() {
        // 英語基礎の不足分
        if let english = categories.first(where: { $0.name == "英語基礎" }) {
            let existing = Set(english.flashcards.map { $0.word })
            let add: [(String, String, String?, String?)] = [
                ("Teacher", "先生", "The teacher is kind.", "ˈtiːtʃər"),
                ("Student", "生徒", "The student studies English.", "ˈstuːdnt"),
                ("Table", "テーブル", "Put the book on the table.", "ˈteɪbəl"),
                ("Chair", "いす", "This chair is comfortable.", "tʃer"),
                ("Window", "窓", "Open the window, please.", "ˈwɪndoʊ"),
                ("Door", "ドア", "Close the door.", "dɔːr"),
                ("Breakfast", "朝食", "I have toast for breakfast.", "ˈbrekfəst"),
                ("Lunch", "昼食", "Let's have lunch together.", "lʌntʃ"),
                ("Dinner", "夕食", "What's for dinner?", "ˈdɪnər"),
                ("Street", "通り", "The street is busy.", "striːt"),
                ("City", "都市", "Tokyo is a big city.", "ˈsɪti"),
                ("Country", "国・田舎", "Japan is a beautiful country.", "ˈkʌntri"),
                ("Music", "音楽", "I love music.", "ˈmjuːzɪk"),
                ("Movie", "映画", "This movie is exciting.", "ˈmuːvi"),
                ("Game", "ゲーム", "Let's play a game.", "ɡeɪm"),
                ("Sport", "スポーツ", "My favorite sport is soccer.", "spɔːrt"),
                ("Weather", "天気", "The weather is nice.", "ˈweðər"),
                ("Rain", "雨", "It may rain today.", "reɪn"),
                ("Snow", "雪", "It will snow tomorrow.", "snoʊ"),
                ("Sun", "太陽", "The sun is bright.", "sʌn")
            ].filter { !existing.contains($0.0) }
            for (w, m, e, p) in add {
                let f = Flashcard(word: w, meaning: m, example: e, pronunciation: p, category: english)
                modelContext.insert(f)
                english.flashcards.append(f)
            }
        }
        
        // 日本語基礎の不足分
        if let japanese = categories.first(where: { $0.name == "日本語基礎" }) {
            let existing = Set(japanese.flashcards.map { $0.word })
            let add: [(String, String, String?, String?)] = [
                ("あめ", "雨", "あめがふっています。", "ame"),
                ("ゆき", "雪", "ゆきがふりました。", "yuki"),
                ("そら", "空", "そらがあおいです。", "sora"),
                ("くるま", "車", "くるまにのります。", "kuruma"),
                ("ともだち", "友達", "ともだちとあそびます。", "tomodachi"),
                ("せんせい", "先生", "せんせいにききます。", "sensei"),
                ("いぬ", "犬", "いぬがほえています。", "inu"),
                ("とけい", "時計", "とけいをみます。", "tokei"),
                ("えき", "駅", "えきにつきました。", "eki"),
                ("きっぷ", "切符", "きっぷをかいます。", "kippu")
            ].filter { !existing.contains($0.0) }
            for (w, m, e, p) in add {
                let f = Flashcard(word: w, meaning: m, example: e, pronunciation: p, category: japanese)
                modelContext.insert(f)
                japanese.flashcards.append(f)
            }
        }
        
        // プログラミング用語の不足分
        if let programming = categories.first(where: { $0.name == "プログラミング用語" }) {
            let existing = Set(programming.flashcards.map { $0.word })
            let add: [(String, String, String?)] = [
                ("Class", "クラス", "class User { }"),
                ("Struct", "構造体", "struct Point { x: Int, y: Int }"),
                ("Enum", "列挙型", "enum Direction { case north }"),
                ("Closure", "クロージャ", "let add = { (a,b) in a+b }"),
                ("Protocol", "プロトコル", "protocol Drawable { }"),
                ("Extension", "拡張", "extension String { }"),
                ("Generic", "ジェネリクス", "func id<T>(_ x:T)->T { x }"),
                ("Async", "非同期", "async let value = fetch()"),
                ("Await", "待機", "let r = await value"),
                ("Actor", "アクタ", "actor Counter { var n = 0 }")
            ].filter { !existing.contains($0.0) }
            for (w, m, e) in add {
                let f = Flashcard(word: w, meaning: m, example: e, category: programming)
                modelContext.insert(f)
                programming.flashcards.append(f)
            }
        }
        
        do { try modelContext.save() } catch { print("アップグレード挿入に失敗: \(error)") }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Category.self, Flashcard.self, StudyProgress.self], inMemory: true)
}
