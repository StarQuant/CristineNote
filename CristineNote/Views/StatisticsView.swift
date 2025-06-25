import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedPeriod: StatisticsPeriod = .thisMonth
    @State private var customStartDate = Calendar.current.startOfDay(for: Date())
    @State private var customEndDate = Date()
    @State private var selectedType: TransactionType = .expense

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 周期选择器
                PeriodSelector(
                    selectedPeriod: $selectedPeriod,
                    customStartDate: $customStartDate,
                    customEndDate: $customEndDate
                )

                // 支出/收入类型选择器
                HStack(spacing: 12) {
                    ForEach([TransactionType.expense, TransactionType.income], id: \.self) { type in
                        Button(action: {
                            selectedType = type
                        }) {
                            Text(type.displayName)
                                .font(.system(.subheadline, weight: .medium))
                                .foregroundColor(selectedType == type ? .white : .primary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(selectedType == type ? type.color : Color(.systemGray6))
                                )
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // 统计概览卡片
                StatisticsOverviewCard(
                    period: selectedPeriod,
                    customStartDate: customStartDate,
                    customEndDate: customEndDate
                )
                .environmentObject(dataManager)

                // 分类饼图
                CategoryPieChartView(
                    data: getStatisticsData()
                )

                // 分类分析
                CategoryAnalysisView(
                    period: selectedPeriod,
                    customStartDate: customStartDate,
                    customEndDate: customEndDate,
                    transactionType: selectedType
                )
                .environmentObject(dataManager)
            }
            .padding()
        }
    }

    private func getStatisticsData() -> [(category: TransactionCategory, amount: Double)] {
        if selectedType == .expense {
            return dataManager.getCategoryExpenses(
                for: selectedPeriod,
                customStartDate: customStartDate,
                customEndDate: customEndDate
            )
        } else {
            return dataManager.getCategoryIncome(
                for: selectedPeriod,
                customStartDate: customStartDate,
                customEndDate: customEndDate
            )
        }
    }
}