import SwiftUI

struct HomePeriodSelector: View {
    @Binding var selectedPeriod: StatisticsPeriod
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach([StatisticsPeriod.today, .thisWeek, .thisMonth], id: \.self) { period in
                    Button(action: {
                        selectedPeriod = period
                    }) {
                        Text(period.localizedName)
                            .font(.system(.subheadline, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedPeriod == period ? Color.blue : Color(.systemGray6))
                            )
                            .foregroundColor(selectedPeriod == period ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
} 