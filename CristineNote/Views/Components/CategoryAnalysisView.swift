import SwiftUI

struct CategoryAnalysisView: View {
    @EnvironmentObject var dataManager: DataManager
    let period: StatisticsPeriod
    let customStartDate: Date
    let customEndDate: Date
    let selectedType: TransactionType?

    private var categoryData: [(category: TransactionCategory, amount: Double)] {
        if let type = selectedType {
            // 特定类型的数据
            if type == .expense {
                return dataManager.getCategoryExpenses(for: period, customStartDate: customStartDate, customEndDate: customEndDate)
            } else {
                return dataManager.getCategoryIncome(for: period, customStartDate: customStartDate, customEndDate: customEndDate)
            }
        } else {
            // 全部类型：合并收入和支出数据
            let expenses = dataManager.getCategoryExpenses(for: period, customStartDate: customStartDate, customEndDate: customEndDate)
            let incomes = dataManager.getCategoryIncome(for: period, customStartDate: customStartDate, customEndDate: customEndDate)
            return (expenses + incomes).sorted { $0.amount > $1.amount }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedString("category_analysis"))
                .font(.headline)

            if categoryData.isEmpty {
                EmptyAnalysisView()
            } else {
                ForEach(Array(categoryData.prefix(5).enumerated()), id: \.1.category.id) { index, item in
                    CategoryAnalysisRow(
                        category: item.category,
                        amount: item.amount,
                        percentage: calculatePercentage(amount: item.amount),
                        rank: index + 1
                    )
                    .environmentObject(dataManager)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }

    private func calculatePercentage(amount: Double) -> Double {
        let total = categoryData.reduce(0) { $0 + $1.amount }
        return total > 0 ? (amount / total) * 100 : 0
    }
}

struct CategoryAnalysisRow: View {
    @EnvironmentObject var dataManager: DataManager
    let category: TransactionCategory
    let amount: Double
    let percentage: Double
    let rank: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(category.color))

            Image(systemName: category.iconName)
                .foregroundColor(category.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName(for: dataManager))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(String(format: "%.1f%%", percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(formatCurrency(amount))
                .font(.subheadline)
                .fontWeight(.semibold)

                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.trailing)
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        return CristineNote.formatCurrency(amount, currency: dataManager.currentSystemCurrency)
    }
}

struct EmptyAnalysisView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text(LocalizedString("no_data"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}