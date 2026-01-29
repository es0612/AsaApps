//
//  WeatherCardView.swift
//  AsaSmartAlarm
//
//  天気カードコンポーネント
//

import SwiftUI

// MARK: - 天気カードビュー

/// 翌朝の天気予報を表示するカード
struct WeatherCardView: View {
    // MARK: - Properties

    let forecast: MorningWeatherForecast?
    let isLoading: Bool
    let onRefresh: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack {
                Label("明日の朝の天気", systemImage: "sunrise.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .animation(
                            isLoading
                                ? .linear(duration: 1).repeatForever(autoreverses: false)
                                : .default,
                            value: isLoading
                        )
                }
                .disabled(isLoading)
            }

            if isLoading && forecast == nil {
                // ローディング
                LoadingView()
            } else if let forecast = forecast {
                // 天気情報
                WeatherContent(forecast: forecast)
            } else {
                // データなし
                NoDataView(onRefresh: onRefresh)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - 天気コンテンツ

private struct WeatherContent: View {
    let forecast: MorningWeatherForecast

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // メイン天気情報
            HStack(spacing: 16) {
                // 天気アイコン
                Image(systemName: forecast.dominantCondition.iconName)
                    .font(.system(size: 48))
                    .foregroundStyle(forecast.dominantCondition.color)

                VStack(alignment: .leading, spacing: 4) {
                    // 天気状態
                    Text(forecast.dominantCondition.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)

                    // 気温範囲
                    Text(forecast.temperatureRangeString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // 場所
                    if let location = forecast.location {
                        Label(location, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()
            }

            // 時間帯別天気
            if !forecast.hourlyData.isEmpty {
                Divider()

                HStack(spacing: 0) {
                    ForEach(forecast.hourlyData) { hourly in
                        HourlyWeatherItem(data: hourly)
                    }
                }
            }

            // アラーム調整提案
            if forecast.shouldAdjustAlarm {
                AdjustmentSuggestion(condition: forecast.dominantCondition)
            }
        }
    }
}

// MARK: - 時間帯別天気アイテム

private struct HourlyWeatherItem: View {
    let data: HourlyWeatherData

    var body: some View {
        VStack(spacing: 4) {
            Text(data.hourString)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Image(systemName: data.weatherCondition.iconName)
                .font(.body)
                .foregroundStyle(data.weatherCondition.color)

            Text(data.temperatureString)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 調整提案

private struct AdjustmentSuggestion: View {
    let condition: WeatherCondition

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            Text("\(condition.displayName)のため、")
                + Text("\(condition.defaultAdjustmentMinutes)分早起き")
                    .fontWeight(.semibold)
                + Text("がおすすめです")
        }
        .font(.caption)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - ローディングビュー

private struct LoadingView: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
            Spacer()
        }
    }
}

// MARK: - データなしビュー

private struct NoDataView: View {
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "cloud.fill")
                .font(.title)
                .foregroundStyle(.secondary)

            Text("天気データがありません")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("取得する", action: onRefresh)
                .font(.caption)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - コンパクト天気バッジ

/// ヘッダーなどで使用するコンパクトな天気バッジ
struct WeatherBadge: View {
    let condition: WeatherCondition
    let temperature: String?

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: condition.iconName)
                .foregroundStyle(condition.color)

            if let temp = temperature {
                Text(temp)
                    .fontWeight(.medium)
            }
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(condition.color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("天気カード - 雨") {
    WeatherCardView(
        forecast: .preview,
        isLoading: false,
        onRefresh: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("天気カード - 晴れ") {
    WeatherCardView(
        forecast: .previewClear,
        isLoading: false,
        onRefresh: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("天気カード - ローディング") {
    WeatherCardView(
        forecast: nil,
        isLoading: true,
        onRefresh: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("天気バッジ") {
    HStack(spacing: 12) {
        WeatherBadge(condition: .rain, temperature: "12°")
        WeatherBadge(condition: .clear, temperature: "18°")
        WeatherBadge(condition: .snow, temperature: "-2°")
    }
    .padding()
}
