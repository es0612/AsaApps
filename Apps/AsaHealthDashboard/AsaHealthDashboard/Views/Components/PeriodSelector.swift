//
//  PeriodSelector.swift
//  AsaHealthDashboard
//
//  期間選択UI
//

import SwiftUI
import AsaUIKit

struct PeriodSelector: View {
    @Binding var selectedPeriod: TimePeriod

    var body: some View {
        HStack(spacing: 12) {
            ForEach(TimePeriod.allCases) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(selectedPeriod == period ? .white : AsaColors.coffeeBrown)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(selectedPeriod == period ? AsaColors.coffeeBrown : AsaColors.softCream)
                        .cornerRadius(20)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - セグメンテッドスタイル

struct SegmentedPeriodSelector: View {
    @Binding var selectedPeriod: TimePeriod

    var body: some View {
        Picker("期間", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    VStack(spacing: 20) {
        PeriodSelector(selectedPeriod: .constant(.week))

        SegmentedPeriodSelector(selectedPeriod: .constant(.week))
    }
    .padding()
}
