import SwiftUI

struct CategoryAnalysisView: View {
    @EnvironmentObject var dataManager: DataManager
    let period: StatisticsPeriod
    let customStartDate: Date
    let customEndDate: Date
    let transactionType: TransactionType

    private var categoryData: [(category: TransactionCategory, amount: Double)] {
        if transactionType == .expense {
            return dataManager.getCategoryExpenses(for: period, customStartDate: customStartDate, customEndDate: customEndDate)
        } else {
            return dataManager.getCategoryIncome(for: period, customStartDate: customStartDate, customEndDate: customEndDate)
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
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = amount.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
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