import WidgetKit
import SwiftUI

// MARK: - Widget Configuration
@main
struct QuoteWidget: Widget {
    let kind: String = "QuoteWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuoteWidgetView(entry: entry)
        }
        .configurationDisplayName("名言ウィジェット")
        .description("毎日新しい名言をお届けします")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget View
struct QuoteWidgetView: View {
    var entry: QuoteEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(quote: entry.quote)
        case .systemMedium:
            MediumWidgetView(quote: entry.quote)
        case .systemLarge:
            LargeWidgetView(quote: entry.quote)
        default:
            MediumWidgetView(quote: entry.quote)
        }
    }
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(quote.category.emoji)
                .font(.title3)
            
            Text(quote.text)
                .font(.footnote)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Text("- \(quote.author)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(quote.category.emoji)
                    .font(.title2)
                Spacer()
                Text(quote.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Text(quote.text)
                .font(.body)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Text("- \(quote.author)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    let quote: Quote
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(quote.category.emoji)
                    .font(.largeTitle)
                Spacer()
                Text(quote.category.displayName)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(6)
            }
            
            Spacer()
            
            Text(quote.text)
                .font(.title3)
                .multilineTextAlignment(.center)
                .lineLimit(6)
                .padding(.horizontal)
            
            Spacer()
            
            Text("- \(quote.author)")
                .font(.footnote)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.horizontal)
            
            HStack {
                Label("名言ウィジェット", systemImage: "book.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    QuoteWidget()
} timeline: {
    QuoteEntry(date: Date(), quote: QuoteDataProvider.shared.sampleQuotes[0])
}

#Preview(as: .systemMedium) {
    QuoteWidget()
} timeline: {
    QuoteEntry(date: Date(), quote: QuoteDataProvider.shared.sampleQuotes[0])
}

#Preview(as: .systemLarge) {
    QuoteWidget()
} timeline: {
    QuoteEntry(date: Date(), quote: QuoteDataProvider.shared.sampleQuotes[0])
}