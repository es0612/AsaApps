import SwiftUI
import WidgetKit

struct QuoteDetailView: View {
    let quote: Quote
    @Environment(\.presentationMode) var presentationMode
    @State private var isFavorite = false
    @State private var showingShareSheet = false
    
    private let sharedDefaults = SharedDefaults.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // カテゴリバッジ
                    categoryBadge
                    
                    // 名言テキスト
                    quoteContent
                    
                    // 作者情報
                    authorSection
                    
                    // アクションボタン
                    actionButtons
                    
                    Spacer(minLength: 50)
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color("AsaSoftCream").opacity(0.3),
                        Color("AsaMutedSage").opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("名言詳細")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
        }
        .onAppear {
            isFavorite = sharedDefaults.isFavorite(quote)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [shareText])
        }
    }
    
    // MARK: - Category Badge
    private var categoryBadge: some View {
        HStack(spacing: 8) {
            Text(quote.category.emoji)
                .font(.title2)
            Text(quote.category.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("AsaCoffeeBrown"))
        )
    }
    
    // MARK: - Quote Content
    private var quoteContent: some View {
        VStack(spacing: 16) {
            Text("\u{201C}")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(Color("AsaCoffeeBrown").opacity(0.3))
                .offset(y: 20)
            
            Text(quote.text)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaDarkSlate"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 8)
            
            Text("\u{201D}")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(Color("AsaCoffeeBrown").opacity(0.3))
                .offset(y: -20)
        }
    }
    
    // MARK: - Author Section
    private var authorSection: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color("AsaMutedSage"))
            
            Text("— \(quote.author)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Divider()
                .background(Color("AsaMutedSage"))
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 20) {
            // お気に入りボタン
            ActionButton(
                title: isFavorite ? "お気に入り解除" : "お気に入りに追加",
                icon: isFavorite ? "heart.fill" : "heart",
                color: Color("AsaCoffeeBrown")
            ) {
                toggleFavorite()
            }
            
            // ウィジェットに設定ボタン
            ActionButton(
                title: "ウィジェットに設定",
                icon: "widget.small",
                color: Color("AsaMutedSage")
            ) {
                setAsWidgetQuote()
            }
        }
    }
    
    // MARK: - Share Text
    private var shareText: String {
        return "\"\(quote.text)\"\n\n— \(quote.author)\n\n#AsaQuoteWidget で名言を共有"
    }
    
    // MARK: - Methods
    private func toggleFavorite() {
        if isFavorite {
            sharedDefaults.removeFavorite(quote)
        } else {
            sharedDefaults.addFavorite(quote)
        }
        isFavorite.toggle()
    }
    
    private func setAsWidgetQuote() {
        sharedDefaults.lastDisplayedQuote = quote
        sharedDefaults.markAsUpdated()
        WidgetCenter.shared.reloadAllTimelines()
        
        // フィードバック表示
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    QuoteDetailView(
        quote: Quote(
            text: "今日という日は、残りの人生の最初の日である",
            author: "アビー・ホフマン",
            category: .encouragement
        )
    )
}