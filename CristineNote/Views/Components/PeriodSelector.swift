import SwiftUI

struct PeriodSelector: View {
    @Binding var selectedPeriod: StatisticsPeriod
    @Binding var customStartDate: Date
    @Binding var customEndDate: Date
    @State private var showingDatePicker = false
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(StatisticsPeriod.allCases, id: \.self) { period in
                    Button(action: {
                        if period == .custom {
                            showingDatePicker = true
                        } else {
                            selectedPeriod = period
                        }
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
        .sheet(isPresented: $showingDatePicker) {
            CustomDateRangePicker(
                startDate: $customStartDate,
                endDate: $customEndDate
            )
            .onDisappear {
                selectedPeriod = .custom
            }
        }
    }
}