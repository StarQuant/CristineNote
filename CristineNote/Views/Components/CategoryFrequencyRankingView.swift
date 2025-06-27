import SwiftUI

struct CategoryFrequencyRankingView: View {
    @EnvironmentObject var dataManager: DataManager
    let period: StatisticsPeriod
    let customStartDate: Date
    let customEndDate: Date
    let selectedType: TransactionType?
    
    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let transactions = dataManager.transactions
        
        // 先按时间筛选
        let dateFilteredTransactions: [Transaction]
        switch period {
        case .today:
            let startOfDay = calendar.startOfDay(for: Date())
            dateFilteredTransactions = transactions.filter { $0.date >= startOfDay }
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            dateFilteredTransactions = transactions.filter { $0.date >= startOfWeek }
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
            dateFilteredTransactions = transactions.filter { $0.date >= startOfMonth }
        case .custom:
            dateFilteredTransactions = transactions.filter { transaction in
                let transactionDate = calendar.startOfDay(for: transaction.date)
                let startDate = calendar.startOfDay(for: customStartDate)
                let endDate = calendar.startOfDay(for: customEndDate)
                return transactionDate >= startDate && transactionDate <= endDate
            }
        case .all:
            dateFilteredTransactions = transactions
        }
        
        // 再按类型筛选
        if let type = selectedType {
            return dateFilteredTransactions.filter { $0.type == type }
        } else {
            return dateFilteredTransactions
        }
    }
    
    private var categoryFrequencyData: [(category: TransactionCategory, count: Int, percentage: Double)] {
        let transactions = filteredTransactions
        guard !transactions.isEmpty else { return [] }
        
        // 统计每个分类的使用次数
        var categoryCount: [UUID: Int] = [:]
        for transaction in transactions {
            categoryCount[transaction.category.id, default: 0] += 1
        }
        
        let totalCount = transactions.count
        
        // 转换为显示数据并排序
        let data = categoryCount.compactMap { (categoryId, count) -> (category: TransactionCategory, count: Int, percentage: Double)? in
            // 从分类ID查找分类
            let allCategories = dataManager.expenseCategories + dataManager.incomeCategories
            guard let category = allCategories.first(where: { $0.id == categoryId }) else { return nil }
            
            let percentage = Double(count) / Double(totalCount) * 100
            return (category: category, count: count, percentage: percentage)
        }
        
        return data.sorted { $0.count > $1.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16, weight: .medium))
                
                Text(LocalizedString("category_frequency_ranking"))
                    .font(.system(.headline, weight: .semibold))
                
                Spacer()
                
                // 显示总交易数
                Text("\(filteredTransactions.count) \(LocalizedString("transactions"))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            }
            
            if categoryFrequencyData.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    
                    Text(LocalizedString("no_frequency_data"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(categoryFrequencyData.enumerated()), id: \.element.category.id) { index, data in
                        CategoryFrequencyRowView(
                            rank: index + 1,
                            category: data.category,
                            count: data.count,
                            percentage: data.percentage,
                            maxCount: categoryFrequencyData.first?.count ?? 1
                        )
                        .environmentObject(dataManager)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

struct CategoryFrequencyRowView: View {
    @EnvironmentObject var dataManager: DataManager
    let rank: Int
    let category: TransactionCategory
    let count: Int
    let percentage: Double
    let maxCount: Int
    
    private var rankColor: Color {
        switch rank {
        case 1:
            return .yellow
        case 2:
            return .gray
        case 3:
            return .brown
        default:
            return .blue
        }
    }
    
    private var rankIcon: String {
        switch rank {
        case 1:
            return "1.circle.fill"
        case 2:
            return "2.circle.fill" 
        case 3:
            return "3.circle.fill"
        default:
            return "\(rank).circle"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 排名图标
            Image(systemName: rankIcon)
                .foregroundColor(rankColor)
                .font(.system(size: 20, weight: .medium))
                .frame(width: 24)
            
            // 分类图标
            Circle()
                .fill(category.color.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: category.iconName)
                        .foregroundColor(category.color)
                        .font(.system(size: 14, weight: .medium))
                )
            
            // 分类信息
            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName(for: dataManager))
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Text("\(count) \(LocalizedString("times"))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1f%%", percentage))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 使用频次条形图
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(count)")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundColor(.primary)
                
                // 频次条形图
                GeometryReader { geometry in
                    let barWidth = geometry.size.width * (Double(count) / Double(maxCount))
                    
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(category.color.opacity(0.3))
                            .frame(width: barWidth, height: 4)
                        
                        Spacer()
                    }
                }
                .frame(width: 60, height: 4)
            }
        }
        .padding(.vertical, 4)
    }
}

// 预览
struct CategoryFrequencyRankingView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryFrequencyRankingView(
            period: .thisMonth,
            customStartDate: Date(),
            customEndDate: Date(),
            selectedType: .expense
        )
        .environmentObject(DataManager())
        .padding()
    }
} 