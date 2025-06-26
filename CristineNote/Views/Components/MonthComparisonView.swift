import SwiftUI
import Charts

struct MonthComparisonData {
    let category: String
    let currentMonth: Double
    let lastMonth: Double
    let change: Double
    let changePercentage: Double
}

struct MonthComparisonView: View {
    @EnvironmentObject var dataManager: DataManager
    let period: StatisticsPeriod
    let customStartDate: Date
    let customEndDate: Date
    let selectedType: TransactionType?
    
    @State private var comparisonData: [MonthComparisonData] = []
    @State private var currentMonthName = ""
    @State private var lastMonthName = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundColor(.mint)
                    .font(.title3)
                
                Text(LocalizedString("month_comparison"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            if comparisonData.isEmpty {
                Text(LocalizedString("no_comparison_data"))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .frame(alignment: .center)
            } else {
                // 月份对比概览
                VStack(spacing: 12) {
                    HStack {
                        Text(currentMonthName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("vs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(lastMonthName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    
                    // 对比柱状图
                    Chart {
                        ForEach(comparisonData, id: \.category) { data in
                            BarMark(
                                x: .value("Amount", data.currentMonth),
                                y: .value("Category", data.category),
                                stacking: .unstacked
                            )
                            .foregroundStyle(.blue)
                            .opacity(0.8)
                            
                            BarMark(
                                x: .value("Amount", data.lastMonth),
                                y: .value("Category", data.category),
                                stacking: .unstacked
                            )
                            .foregroundStyle(.gray)
                            .opacity(0.6)
                        }
                    }
                    .frame(height: 160)
                    .padding(.horizontal, 20)
                    .chartXAxis {
                        AxisMarks(position: .bottom) { value in
                            AxisValueLabel {
                                if let amount = value.as(Double.self) {
                                    Text(formatShortCurrency(amount))
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let category = value.as(String.self) {
                                    Text(category)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    
                    // 图例
                    HStack(spacing: 20) {
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(.blue)
                                .opacity(0.8)
                                .frame(width: 12, height: 8)
                            Text(currentMonthName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(.gray)
                                .opacity(0.6)
                                .frame(width: 12, height: 8)
                            Text(lastMonthName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
                
                // 详细对比列表
                VStack(spacing: 0) {
                    ForEach(comparisonData, id: \.category) { data in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(data.category)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                HStack(spacing: 8) {
                                    Text(formatCurrency(data.currentMonth))
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    Text("vs")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(formatCurrency(data.lastMonth))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                HStack(spacing: 4) {
                                    Image(systemName: data.change >= 0 ? "arrow.up" : "arrow.down")
                                        .font(.caption)
                                        .foregroundColor(data.change >= 0 ? .red : .green)
                                    
                                    Text(formatCurrency(abs(data.change)))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(data.change >= 0 ? .red : .green)
                                }
                                
                                Text("\(data.change >= 0 ? "+" : "")\(String(format: "%.1f", data.changePercentage))%")
                                    .font(.caption)
                                    .foregroundColor(data.change >= 0 ? .red : .green)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        
                        if data.category != comparisonData.last?.category {
                            Divider()
                                .padding(.horizontal, 20)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
        )
        .onAppear {
            loadComparisonData()
        }
        .onChange(of: period) { _ in
            loadComparisonData()
        }
        .onChange(of: selectedType) { _ in
            loadComparisonData()
        }
    }
    
    private func loadComparisonData() {
        let calendar = Calendar.current
        let now = Date()
        
        // 获取当前月和上个月的开始结束日期
        guard let currentMonthStart = calendar.dateInterval(of: .month, for: now)?.start,
              let currentMonthEnd = calendar.date(byAdding: .day, value: -1, to: calendar.date(byAdding: .month, value: 1, to: currentMonthStart)!),
              let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: currentMonthStart),
              let lastMonthEnd = calendar.date(byAdding: .day, value: -1, to: currentMonthStart) else {
            return
        }
        
        // 设置月份名称
        let formatter = DateFormatter()
        formatter.dateFormat = LocalizationManager.shared.currentLanguage == "zh-Hans" ? "MM月" : "MMM"
        currentMonthName = formatter.string(from: now)
        lastMonthName = formatter.string(from: lastMonthStart)
        
        var data: [MonthComparisonData] = []
        
        if selectedType == nil {
            // 全部模式：比较收入、支出、结余
            let currentIncome = dataManager.getTotalIncome(for: .custom, customStartDate: currentMonthStart, customEndDate: currentMonthEnd)
            let lastIncome = dataManager.getTotalIncome(for: .custom, customStartDate: lastMonthStart, customEndDate: lastMonthEnd)
            let incomeChange = currentIncome - lastIncome
            let incomeChangePercentage = lastIncome > 0 ? (incomeChange / lastIncome) * 100 : 0
            
            let currentExpense = dataManager.getTotalExpense(for: .custom, customStartDate: currentMonthStart, customEndDate: currentMonthEnd)
            let lastExpense = dataManager.getTotalExpense(for: .custom, customStartDate: lastMonthStart, customEndDate: lastMonthEnd)
            let expenseChange = currentExpense - lastExpense
            let expenseChangePercentage = lastExpense > 0 ? (expenseChange / lastExpense) * 100 : 0
            
            let currentBalance = currentIncome - currentExpense
            let lastBalance = lastIncome - lastExpense
            let balanceChange = currentBalance - lastBalance
            let balanceChangePercentage = lastBalance != 0 ? (balanceChange / abs(lastBalance)) * 100 : 0
            
            data = [
                MonthComparisonData(
                    category: LocalizedString("income"),
                    currentMonth: currentIncome,
                    lastMonth: lastIncome,
                    change: incomeChange,
                    changePercentage: incomeChangePercentage
                ),
                MonthComparisonData(
                    category: LocalizedString("expense"),
                    currentMonth: currentExpense,
                    lastMonth: lastExpense,
                    change: expenseChange,
                    changePercentage: expenseChangePercentage
                ),
                MonthComparisonData(
                    category: LocalizedString("surplus"),
                    currentMonth: currentBalance,
                    lastMonth: lastBalance,
                    change: balanceChange,
                    changePercentage: balanceChangePercentage
                )
            ]
        } else if selectedType == .income {
            // 收入模式：比较收入分类
            let currentData = dataManager.getCategoryIncome(for: .custom, customStartDate: currentMonthStart, customEndDate: currentMonthEnd)
            let lastData = dataManager.getCategoryIncome(for: .custom, customStartDate: lastMonthStart, customEndDate: lastMonthEnd)
            data = createCategoryComparison(current: currentData, last: lastData)
        } else {
            // 支出模式：比较支出分类
            let currentData = dataManager.getCategoryExpenses(for: .custom, customStartDate: currentMonthStart, customEndDate: currentMonthEnd)
            let lastData = dataManager.getCategoryExpenses(for: .custom, customStartDate: lastMonthStart, customEndDate: lastMonthEnd)
            data = createCategoryComparison(current: currentData, last: lastData)
        }
        
        comparisonData = data
    }
    
    private func createCategoryComparison(current: [(category: TransactionCategory, amount: Double)], last: [(category: TransactionCategory, amount: Double)]) -> [MonthComparisonData] {
        var result: [MonthComparisonData] = []
        var lastDataDict = Dictionary(uniqueKeysWithValues: last.map { ($0.category.id, $0.amount) })
        
        // 处理当前月的分类
        for item in current.prefix(5) { // 只显示前5个
            let lastAmount = lastDataDict[item.category.id] ?? 0
            let change = item.amount - lastAmount
            let changePercentage = lastAmount > 0 ? (change / lastAmount) * 100 : 0
            
            result.append(MonthComparisonData(
                category: item.category.displayName(for: dataManager),
                currentMonth: item.amount,
                lastMonth: lastAmount,
                change: change,
                changePercentage: changePercentage
            ))
            
            lastDataDict.removeValue(forKey: item.category.id)
        }
        
        return result
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        return CristineNote.formatCurrency(amount, currency: dataManager.currentSystemCurrency)
    }
    
    private func formatShortCurrency(_ amount: Double) -> String {
        let currency = dataManager.currentSystemCurrency
        
        if abs(amount) >= 1000000 {
            return String(format: "%@%.1fM", currency.symbol, amount / 1000000)
        } else if abs(amount) >= 1000 {
            return String(format: "%@%.1fK", currency.symbol, amount / 1000)
        } else {
            return String(format: "%@%.0f", currency.symbol, amount)
        }
    }
} 