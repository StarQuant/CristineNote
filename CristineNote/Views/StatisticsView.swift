import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedPeriod: StatisticsPeriod = .thisMonth
    @State private var customStartDate = Calendar.current.startOfDay(for: Date())
    @State private var customEndDate = Date()
    @State private var selectedType: TransactionType? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 支出/收入类型选择器 - 移到第一行，增加"全部"选项
                HStack(spacing: 12) {
                    Button(action: {
                        selectedType = nil
                    }) {
                        Text(LocalizedString("all"))
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundColor(selectedType == nil ? .white : .primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedType == nil ? Color.blue : Color(.systemGray6))
                            )
                    }
                    
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

                // 周期选择器 - 移到第二行
                PeriodSelector(
                    selectedPeriod: $selectedPeriod,
                    customStartDate: $customStartDate,
                    customEndDate: $customEndDate
                )

                // 统计概览卡片 - 使用与首页一致的布局
                StatisticsCompactOverviewCard(
                    period: selectedPeriod,
                    customStartDate: customStartDate,
                    customEndDate: customEndDate,
                    selectedType: selectedType
                )
                .environmentObject(dataManager)

                // 月度趋势图
                MonthlyTrendChartView(selectedType: selectedType)
                    .environmentObject(dataManager)

                // 日消费模式图
                DailyConsumptionPatternView(
                    period: selectedPeriod,
                    customStartDate: customStartDate,
                    customEndDate: customEndDate,
                    selectedType: selectedType
                )
                .environmentObject(dataManager)

                // 支出排行统计
                ExpenseRankingView(
                    period: selectedPeriod,
                    customStartDate: customStartDate,
                    customEndDate: customEndDate,
                    selectedType: selectedType
                )
                .environmentObject(dataManager)

                // 分类使用频次排行
                CategoryFrequencyRankingView(
                    period: selectedPeriod,
                    customStartDate: customStartDate,
                    customEndDate: customEndDate,
                    selectedType: selectedType
                )
                .environmentObject(dataManager)

                // 与上月对比统计
                MonthComparisonView(
                    period: selectedPeriod,
                    customStartDate: customStartDate,
                    customEndDate: customEndDate,
                    selectedType: selectedType
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
                    selectedType: selectedType
                )
                .environmentObject(dataManager)
            }
            .padding()
        }
    }

    private func getStatisticsData() -> [(category: TransactionCategory, amount: Double)] {
        if let type = selectedType {
            // 选择了特定类型
            if type == .expense {
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
        } else {
            // 选择了全部，合并收入和支出数据
            let expenses = dataManager.getCategoryExpenses(
                for: selectedPeriod,
                customStartDate: customStartDate,
                customEndDate: customEndDate
            )
            let incomes = dataManager.getCategoryIncome(
                for: selectedPeriod,
                customStartDate: customStartDate,
                customEndDate: customEndDate
            )
            return expenses + incomes
        }
    }
}