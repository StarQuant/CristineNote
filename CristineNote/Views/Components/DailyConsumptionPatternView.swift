import SwiftUI
import Charts

struct DailyPatternData {
    let day: String
    let amount: Double
    let date: Date
}

struct DailyConsumptionPatternView: View {
    @EnvironmentObject var dataManager: DataManager
    let period: StatisticsPeriod
    let customStartDate: Date
    let customEndDate: Date
    let selectedType: TransactionType?
    
    @State private var patternData: [DailyPatternData] = []
    @State private var showWeeklyPattern = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                Text(showWeeklyPattern ? LocalizedString("weekly_pattern") : LocalizedString("daily_pattern"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // 切换按钮：周模式 vs 日模式
                Button(action: {
                    showWeeklyPattern.toggle()
                    loadPatternData()
                }) {
                    Image(systemName: showWeeklyPattern ? "calendar.day.timeline.left" : "calendar")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 20)
            
            if patternData.isEmpty {
                Text(LocalizedString("no_pattern_data"))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .frame(alignment: .center)
            } else {
                Chart(patternData, id: \.day) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Amount", data.amount)
                    )
                    .foregroundStyle(getBarColor(for: data.amount))
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .padding(.horizontal, 20)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(formatShortCurrency(amount))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let day = value.as(String.self) {
                                Text(day)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // 统计信息
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedString("average"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(getAverageAmount()))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedString("highest"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(getHighestAmount()))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedString("lowest"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(getLowestAmount()))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
        )
        .onAppear {
            loadPatternData()
        }
        .onChange(of: period) { _ in
            loadPatternData()
        }
        .onChange(of: selectedType) { _ in
            loadPatternData()
        }
        .onChange(of: customStartDate) { _ in
            loadPatternData()
        }
        .onChange(of: customEndDate) { _ in
            loadPatternData()
        }
    }
    
    private func loadPatternData() {
        let calendar = Calendar.current
        var data: [DailyPatternData] = []
        
        if showWeeklyPattern {
            // 周模式：显示周一到周日的平均消费
            let weekdays = LocalizationManager.shared.currentLanguage == "zh-Hans" ? 
                ["周一", "周二", "周三", "周四", "周五", "周六", "周日"] : 
                ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            
            for (index, weekday) in weekdays.enumerated() {
                let weekdayIndex = index + 2 // Calendar.weekday: 1=Sunday, 2=Monday...
                let actualWeekday = weekdayIndex > 7 ? 1 : weekdayIndex
                
                let amount = getAverageAmountForWeekday(actualWeekday)
                data.append(DailyPatternData(
                    day: weekday,
                    amount: amount,
                    date: Date()
                ))
            }
        } else {
            // 日模式：显示选定周期内每天的消费
            let transactions = dataManager.getTransactions(for: period, customStartDate: customStartDate, customEndDate: customEndDate)
            
            var dailyAmounts: [String: Double] = [:]
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd"
            
            for transaction in transactions {
                if let type = selectedType {
                    if transaction.type != type { continue }
                }
                
                let dayKey = formatter.string(from: transaction.date)
                let convertedAmount = dataManager.exchangeRateService.convert(
                    amount: transaction.originalAmount,
                    from: transaction.originalCurrency,
                    to: dataManager.currentSystemCurrency
                )
                
                if transaction.type == .expense {
                    dailyAmounts[dayKey, default: 0] += convertedAmount
                } else if selectedType == .income {
                    dailyAmounts[dayKey, default: 0] += convertedAmount
                }
            }
            
            for (day, amount) in dailyAmounts.sorted(by: { $0.key < $1.key }) {
                data.append(DailyPatternData(
                    day: day,
                    amount: amount,
                    date: Date()
                ))
            }
        }
        
        patternData = data
    }
    
    private func getAverageAmountForWeekday(_ weekday: Int) -> Double {
        let calendar = Calendar.current
        let transactions = dataManager.transactions
        
        var weekdayTransactions: [Transaction] = []
        
        for transaction in transactions {
            if calendar.component(.weekday, from: transaction.date) == weekday {
                if let type = selectedType {
                    if transaction.type == type {
                        weekdayTransactions.append(transaction)
                    }
                } else if transaction.type == .expense {
                    weekdayTransactions.append(transaction)
                }
            }
        }
        
        if weekdayTransactions.isEmpty { return 0 }
        
        let totalAmount = weekdayTransactions.reduce(0) { result, transaction in
            let convertedAmount = dataManager.exchangeRateService.convert(
                amount: transaction.originalAmount,
                from: transaction.originalCurrency,
                to: dataManager.currentSystemCurrency
            )
            return result + convertedAmount
        }
        
        // 计算这个星期几出现的次数
        let uniqueDates = Set(weekdayTransactions.map { calendar.startOfDay(for: $0.date) })
        
        return uniqueDates.count > 0 ? totalAmount / Double(uniqueDates.count) : 0
    }
    
    private func getBarColor(for amount: Double) -> Color {
        if selectedType == .income {
            return .green
        } else {
            return .red
        }
    }
    
    private func getAverageAmount() -> Double {
        guard !patternData.isEmpty else { return 0 }
        return patternData.reduce(0) { $0 + $1.amount } / Double(patternData.count)
    }
    
    private func getHighestAmount() -> Double {
        patternData.max(by: { $0.amount < $1.amount })?.amount ?? 0
    }
    
    private func getLowestAmount() -> Double {
        patternData.min(by: { $0.amount < $1.amount })?.amount ?? 0
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
    
    private func formatCurrency(_ amount: Double) -> String {
        return CristineNote.formatCurrency(amount, currency: dataManager.currentSystemCurrency)
    }
} 