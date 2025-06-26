import SwiftUI
import Charts

struct ExpenseRankingItem {
    let category: TransactionCategory
    let amount: Double
    let percentage: Double
    let rank: Int
}

struct ExpenseRankingView: View {
    @EnvironmentObject var dataManager: DataManager
    let period: StatisticsPeriod
    let customStartDate: Date
    let customEndDate: Date
    let selectedType: TransactionType?
    
    @State private var rankingData: [ExpenseRankingItem] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.number")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text(selectedType == .income ? LocalizedString("income_ranking") : LocalizedString("expense_ranking"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            if rankingData.isEmpty {
                Text(LocalizedString("no_ranking_data"))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .frame(alignment: .center)
            } else {
                VStack(spacing: 0) {
                    // 排行榜列表
                    ForEach(Array(rankingData.prefix(5).enumerated()), id: \.element.category.id) { index, item in
                        HStack(spacing: 12) {
                            // 排名标识
                            ZStack {
                                Circle()
                                    .fill(getRankColor(item.rank))
                                    .frame(width: 24, height: 24)
                                
                                Text("\(item.rank)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            // 分类图标和名称
                            HStack(spacing: 8) {
                                Image(systemName: item.category.iconName)
                                    .foregroundColor(item.category.color)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.category.displayName(for: dataManager))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text("\(Int(item.percentage))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // 金额
                            Text(formatCurrency(item.amount))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedType == .income ? .green : .red)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        
                        if index < min(4, rankingData.count - 1) {
                            Divider()
                                .padding(.horizontal, 20)
                        }
                    }
                    
                    // 如果有更多数据，显示提示
                    if rankingData.count > 5 {
                        HStack {
                            Text(LocalizedString("more_categories"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("共\(rankingData.count)个分类")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                }
                
                // 柱状图显示前5名
                Chart(Array(rankingData.prefix(5)), id: \.category.id) { item in
                    BarMark(
                        x: .value("Amount", item.amount),
                        y: .value("Category", item.category.displayName(for: dataManager))
                    )
                    .foregroundStyle(selectedType == .income ? .green : .red)
                    .cornerRadius(4)
                }
                .frame(height: 150)
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
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
        )
        .onAppear {
            loadRankingData()
        }
        .onChange(of: period) { _ in
            loadRankingData()
        }
        .onChange(of: selectedType) { _ in
            loadRankingData()
        }
        .onChange(of: customStartDate) { _ in
            loadRankingData()
        }
        .onChange(of: customEndDate) { _ in
            loadRankingData()
        }
    }
    
    private func loadRankingData() {
        var categoryData: [(category: TransactionCategory, amount: Double)] = []
        
        if selectedType == .income {
            categoryData = dataManager.getCategoryIncome(
                for: period,
                customStartDate: customStartDate,
                customEndDate: customEndDate
            )
        } else {
            categoryData = dataManager.getCategoryExpenses(
                for: period,
                customStartDate: customStartDate,
                customEndDate: customEndDate
            )
        }
        
        let totalAmount = categoryData.reduce(0) { $0 + $1.amount }
        
        rankingData = categoryData.enumerated().map { index, item in
            ExpenseRankingItem(
                category: item.category,
                amount: item.amount,
                percentage: totalAmount > 0 ? (item.amount / totalAmount) * 100 : 0,
                rank: index + 1
            )
        }
    }
    
    private func getRankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow    // 金色
        case 2: return .gray      // 银色
        case 3: return .orange    // 铜色
        default: return .blue     // 其他
        }
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